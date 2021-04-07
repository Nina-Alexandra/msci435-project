% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

teams      = 12; % number of teams
events     = 4; % number of events: floor, vault bars, beam
eventNames = ["floor", "vault", "bars", "beam"];
facilities = 2; % number of facilities
B          = 1; % number of broadcast channels

facilityHours = 14;   % available facility time (total facility hours in a day)
epochSize = 60; % given in minutes
nEpochs = facilityHours*60/epochSize; 

% the duration of the activity of type τ (row) for event e (col) for a single team
% time represented in minutes
durationsMinutes = [51,30,30,36];
durationsEpochs = ceil(durationsMinutes./epochSize);

% broadcast weight for the event (row) and time slot (col)
broadcastWeights = reshape(broadcastMatrix(nEpochs, events),[],1);

% initalize model
model.modelname = 'gymnastics_2';
model.modelsense = 'max';
params.outputflag = 0;
    
% set data for variables
nX = teams*events*nEpochs;
nY = events*nEpochs;

ncol = nX + nY;
model.lb    = zeros(ncol, 1);
model.ub    = ones(ncol, 1);
model.obj   = [zeros(nX,1);broadcastWeights];
model.vtype = repmat('B', ncol, 1);
    
% set up constraints
%nC1 = nEpochs*facilities;
nC1=0;
nC2 = nEpochs*teams;
nC3 = teams*events;
nC4 = nEpochs*events*facilities;
nC5 = nEpochs;
nC6 = nEpochs*events;
nConstraints = nC1+nC2+nC3+nC4+nC5+nC6;

model.A     = sparse(nConstraints, ncol);
% model.rhs   = [epochSize*ones(nC1,1);
%                ones(nC2+nC3+nC4+nC5,1);
%                zeros(nC6,1)];
model.rhs   = [ones(nC2+nC3+nC4,1);
               B*ones(nC5,1);
               zeros(nC6,1)];
model.sense = [repmat('<', nC1+nC2,1);repmat('=', nC3,1);repmat('<', nC4+nC5+nC6,1)];

% fill A matrix
%model.A(1:nC1,:)  = constraint1(nEpochs,teams, events, facilities, durationsMinutes);
colsFilled = nC1;
model.A(colsFilled+1:colsFilled+nC2,:) = constraint2(nEpochs, teams, events);
colsFilled = colsFilled + nC2;
model.A(colsFilled+1:colsFilled+nC3,:) = constraint3(nEpochs, teams, events);
colsFilled = colsFilled + nC3;
model.A(colsFilled+1:colsFilled+nC4,:) = constraint4(nEpochs, teams, events, facilities);
colsFilled = colsFilled + nC4;
model.A(colsFilled+1:colsFilled+nC5,:) = constraint5(nEpochs, teams, events);
colsFilled = colsFilled + nC5;
model.A(colsFilled+1:colsFilled+nC6,:) = constraint6(nEpochs, teams, events);

% solve model
result = gurobi(model,params);

% format results

x_vars = reshape(result.x(1:nX),[nEpochs,teams*events]);
y_vars = reshape(result.x(nX+1:ncol), [nEpochs, events]);

x_results = zeros(nEpochs,events*facilities);
for e=1:events
    for t=1:teams
        for s=1:nEpochs
            if x_vars(s,4*(t-1)+e)~=0
                if t<= teams/facilities
                    x_results(s,e) = t;
                else
                    x_results(s,e+events) = t;
                end
            end
        end
    end
end

colNamesX = cell(1,facilities*events);
counter=1;
for f=1:facilities
    for e=1:events
        colNamesX{counter} = ['F' num2str(f) '-' eventNames{e}];
        counter = counter + 1;
    end
end

colNamesY = cell(1,events);
for e=1:events
    colNamesY{e} = eventNames{e};
end

epochLabels = cell(1,nEpochs);
for s=1:nEpochs
    epochLabels{s} = num2str(s,'%02d');
end

tableX = array2table(x_results);
tableX.Properties.VariableNames(:) = colNamesX;
tableX.Properties.RowNames(:) = epochLabels;

tableY = array2table(y_vars);
tableY.Properties.VariableNames(:) = colNamesY;
tableY.Properties.RowNames(:) = epochLabels;

disp(tableX);
disp(tableY);
disp(['Objective Function: ' num2str(result.objval)]);

function c1 = constraint1(slots, T, E, F, durMinutes)
    rows = slots*F;
    Ay = zeros(rows,slots*E);
    Ax = zeros(rows,T*E*slots);
    
    TinF = T/F;
    Ax_base1 = eye(slots);
    Ax_base2 = zeros(slots, TinF*E*slots);
    empty = zeros(slots,TinF*E*slots);
    for te=1:TinF*E
        e = mod(te,E);
        if e==0
            e = 4;
        end
        Ax_base2(:,slots*(te-1)+1:slots*te) = durMinutes(e)*Ax_base1;
    end
    for f=1:F
        Ax(slots*(f-1)+1:slots*f,:) = [repmat(empty,1,(f-1)),Ax_base2,repmat(empty,1,(F-f))];
    end
    c1 = [Ax,Ay];
end

function c2 = constraint2(slots, T, E)
    rows = T*slots;
    Ay = zeros(rows,slots*E);
    Ax = zeros(rows,T*E*slots);
    
    Ax_base = repmat(eye(slots),1,E);
    empty = repmat(zeros(slots),1,E);
    for t=1:T
        Ax(slots*(t-1)+1:slots*t,:) = [repmat(empty,1,t-1),Ax_base,repmat(empty,1,T-t)];
    end
    c2 = [Ax,Ay];
end

function c3 = constraint3(slots, T, E)
    rows = T*E;
    Ay = zeros(rows,slots*E);
    Ax = zeros(rows,T*E*slots);
    
    for te=1:T*E
        Ax(te,:) = [zeros(1,slots*(te-1)),ones(1,slots),zeros(1,slots*(T*E-te))];
    end
    c3 = [Ax,Ay];
end

function c4 = constraint4(slots, T, E, F)
    rows = slots*E*F;
    Ay = zeros(rows,slots*E);
    Ax = zeros(rows,T*E*slots);
    
    Ax_base = eye(slots*E);
    empty = zeros(slots*E);
    TinF = T/F;
    for f=1:F
        Ax(slots*E*(f-1)+1:slots*E*f,:) = [repmat(empty,1,TinF*(f-1)),repmat(Ax_base,1,TinF),repmat(empty,1,TinF*(F-f))];
    end
    c4 = [Ax,Ay];
end

function c5 = constraint5(slots, T, E)
    rows = slots;
    Ay = zeros(rows,slots*E);
    Ax = zeros(rows,T*E*slots);
    
    Ay_base = eye(rows);
    Ay(:,:) = repmat(Ay_base,1,E);
    c5 = [Ax,Ay];
end

function c6 = constraint6(slots, T, E)
    Ay = eye(slots*E);
    
    Ax_base = -1*eye(slots*E);
    Ax = repmat(Ax_base,1,T);
        
    c6 = [Ax,Ay];
end