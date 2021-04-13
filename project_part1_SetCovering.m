% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

teams      = 12; % number of teams
tau        = 1; % number of activity types: warm-up and competition are combined
events     = 4; % number of events: floor, vault bars, beam
eventNames = ["floor", "vault", "bars", "beam"];
facilities = 2; % number of facilities

D   = 14;   % available facility time (total facility hours in a day)
phi = 0.25;  % the percent of D during which a team can be active

% the duration of the activity of type τ for event e for a single team
% time represented in hours
% with warm-ups and competitions as seperate activities:
%durations = [0.75; 0.4; 0.4; 0.5; 0.1; 0.1; 0.1; 0.1];

% with warm-ups and competitions combined
durations = [1; 0.5; 0.5; 1];

schedSize = teams*tau*events;

% generate the first schedule
schedCollection=genSched(teams, tau, events, phi, D, durations);

% build model
model.modelname = 'gymnastics';
model.modelsense = 'min';
params.outputflag = 0;
    
% set data for variables
ncol = 1;
model.lb    = zeros(ncol, 1);
model.ub    = ones(ncol, 1);
model.obj   = ones(ncol, 1);
model.vtype = repmat('B', ncol, 1);
    
% generate constraints
model.A     = sparse(schedSize, ncol);
model.rhs   = ones(schedSize,1);
model.sense = repmat('=', schedSize, 1);

% fill A matrix
for s=1:schedSize
    model.A(s,1) = schedCollection(s,1);
end

% solve model
result = gurobi(model,params);

iteration = 1;
while ~strcmp(result.status, 'OPTIMAL')
    iteration = iteration + 1;
    disp(['Solving... Iteration ' num2str(iteration)]);
    % generate a new schedule and append to the collection
    schedCollection=[schedCollection,genSched(teams, tau, events, phi, D, durations)];

    % update data for variables
    ncol = ncol + 1;
    model.lb    = [model.lb; 0];
    model.ub    = [model.ub; 1];
    model.obj   = [model.obj; 1];
    model.vtype = [model.vtype; 'B'];
    
    % update constraints
    model.A = sparse(schedSize, ncol);
    
    for s=1:schedSize
        for h=1:ncol
            model.A(s,h) = schedCollection(s,h);
        end
    end
    
    % re-solve model
    result = gurobi(model,params);
end

% Interpret & display the model results
selectedScheds = schedCollection(1:events,find(result.x));
nDays = sum(result.x);

colNames = cell(1,nDays);
for d=1:nDays
    colNames{d} = ['Day ' num2str(d)];
end

rowNames = cell(1,events);
for e=1:events
    rowNames{e} = eventNames{e};
end

tableX = array2table(selectedScheds);
tableX.Properties.VariableNames(:) = colNames;
tableX.Properties.RowNames(:) = rowNames;

disp(tableX);

function gs = genSched(T, tau, E, phi, D, dur)
    valid = false;
    v1=0;
    v2=0;
    while valid == false
        % generate a random schedule
        % https://www.mathworks.com/matlabcentral/answers/111540-generating-a-random-binary-matrix
        shortSched = randi([0 1],E,1);
        sched = repmat(shortSched,T*tau,1);

        % validate the schedule
        % A team’s activities in a day can’t exceed phi*D
        checkTeamsActivities=zeros(T,1);
        for t=1:T
            if sched((t-1)*tau*E+1:t*tau*E).'*dur<=phi*D
                checkTeamsActivities(t)=1;
            end
        end
        if sum(checkTeamsActivities)==T
            v1=1;
        end
        
        % An event’s activities in a day can’t exceed the available facility time
        % Max(F1 warm-up, F2 warm-up)+competition time if not allowing
        % overlap of a competition event across all facilities
        % otherwise Max(F1 warm-up + F1 competition, F2 warm-up + F2
        % competition)
        checkEventsActivities=zeros(E,1);
        for e=1:E
            fac1WarmUp=0;
            fac2WarmUp=0;
            compTime1=0;
            compTime2=0;
            for t=1:T
                if t<=T/2
                    fac1WarmUp = fac1WarmUp + sched((t-1)*tau*E+e)*dur(e);
                    % uncomment the following if tau=2 and overlap across
                    % facilities allowed:
                    %compTime1 = compTime1 + sched((t-1)*tau*E+E+e)*dur(E+e);
                else
                    fac2WarmUp = fac2WarmUp + sched((t-1)*tau*E+e)*dur(e);
                    % uncomment the following if tau=2 and overlap across
                    % facilities allowed:
                    %compTime2 = compTime2 + sched((t-1)*tau*E+E+e)*dur(E+e);
                end
                % uncomment if tau=2 and overlap of competitions between
                % facilities NOT allowed:
                %compTime = compTime + sched((t-1)*tau*E+E+e)*dur(E+e);
            end
            % uncomment if tau=2 and overlap of competitions between
            % facilities NOT allowed:
            %if max(fac1WarmUp, fac2WarmUp)+compTime<=D
            if max(fac1WarmUp+compTime1, fac2WarmUp+compTime2)<=D
                checkEventsActivities(e)=1;
            end

        end
        if sum(checkEventsActivities)==E
            v2=1;
        end

        % If all tests pass then add sched to schedCollection
        if (v1+v2)==2
            valid=true;
        end
    end
    gs = sched;
end