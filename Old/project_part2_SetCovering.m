% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

teams      = 12; % number of teams
tau        = 2; % number of activity types: warm-up and competition
events     = 4; % number of events: floor, vault bars, beam
facilities = 2; % number of facilities

facilityHours = 14;   % available facility time (total facility hours in a day)
epochSize = 6; %given in minutes
nEpochs = facilityHours*60/epochSize; 

% the duration of the activity of type τ (row) for event e (col) for a single team
% time represented in epochs
durationsMatrix = [7,4,4,5;
                    1,1,1,1];
durations = reshape(durationsMatrix',1,[]);

% broadcast weight for the event (row) and time slot (col)
broadcastWeightsMatrix = [repmat(4,1,nEpochs);
                          repmat(3,1,nEpochs);
                          repmat(3,1,nEpochs);
                          repmat(2,1,nEpochs)];
broadcastWeights = reshape(broadcastWeightsMatrix',1,[]);

% generate the first schedule
firstSched = genSched(events, nEpochs, durationsMatrix);
firstSchedCost = broadcastWeights*firstSched;

schedCollection=[firstSched, firstSched];

% build model
model.modelname = 'gymnastics_2';
model.modelsense = 'max';
    
% set data for variables
ncol = 2;
model.lb    = zeros(ncol, 1);
model.ub    = ones(ncol, 1);
model.obj   = [firstSchedCost; firstSchedCost];
model.vtype = repmat('B', ncol, 1);
    
% generate constraints
nC1 = events*nEpochs;
nConstraints = nC1+facilities;

model.A     = sparse(nConstraints, ncol);
model.rhs   = [2*ones(nC1,1);teams/facilities*ones(facilities,1)];
model.sense = [repmat('<', nC1, 1);repmat('=', facilities, 1)];

% fill A matrix
for s=1:nC1
    model.A(s,1) = schedCollection(s,1);
    model.A(s,2) = schedCollection(s,1);
end
model.A(nC1+1,1) = 1;
model.A(nC1+2,2) = 1;

% solve model
result = gurobi(model)

while ~strcmp(result.status, 'OPTIMAL')
    % generate a new schedule and append to the collection
    newSched = genSched(events, nEpochs, durationsMatrix)
    newSchedCost = broadcastWeights*newSched;
    schedCollection=[schedCollection,newSched,newSched];

    % update data for variables
    ncol = ncol + 2;
    model.lb    = [model.lb; 0; 0];
    model.ub    = [model.ub; 1; 1];
    model.obj   = [model.obj; newSchedCost; newSchedCost];
    model.vtype = [model.vtype; 'B'; 'B'];
    
    % update constraints
    model.A = sparse(nConstraints, ncol);
    
    for s=1:nC1
        for h=1:ncol
            model.A(s,h) = schedCollection(s,h);
        end
    end
    
    for h=1:ncol
        if mod(h,2)==1
            model.A(nC1+1,h) = 1;
        else
            model.A(nC1+2,h) = 1;
        end
    end
    
    % resolve model
    result = gurobi(model)
end

result.x

function gs = genSched(E, slots, dur_matrix)
    valid = false;
    while valid == false
        sched = zeros(slots,E);
        for e=1:E
            warmUpDur = dur_matrix(1,e);
            compDur = dur_matrix(2,e);
            warmUp = ones(warmUpDur,1);
            comp = 2*ones(compDur,1);
            slotsUsed = warmUpDur + compDur;
            slotsBefore = randi([0 (slots - slotsUsed)],1,1);
            slotsUsed = slotsUsed + slotsBefore;
            slotsBetween = randi([0 (slots - slotsUsed)],1,1);
            slotsUsed = slotsUsed + slotsBetween;
            slotsRemaining = slots - slotsUsed;
            schedE = [zeros(slotsBefore,1);warmUp;zeros(slotsBetween,1);comp;zeros(slotsRemaining,1)];
            sched(:,e) = schedE;
        end

        % validate the schedule
        % A team can only do one activity-event at a time
        checkNoOverlap=zeros(slots,1);
        for s=1:slots
            if nnz(sched(s,:))<=1
                checkNoOverlap(s)=1;
            end
        end
        
        if sum(checkNoOverlap)==slots
            valid=true;
        end
       
    end
    gs = reshape(sched,[],1);
end