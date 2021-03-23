% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

teams      = 8; % number of teams
tau        = 2; % number of activity types: warm-up and competition
events     = 4; % number of events: floor, vault bars, beam
facilities = 2; % number of facilities

D   = 14;   % available facility time (total facility hours in a day)
phi = 0.202;  % the percent of D during which a team can be active

% the duration of the activity of type τ (row) for event e (col) for a single team
% time represented in hours; 0.33 hours ~20 min; 0.094 hours ~5.625 min
durations = [0.33; 0.33; 0.33; 0.33; 0.094; 0.094; 0.094; 0.094];

schedSize = teams*tau*events;

% generate the first schedule
schedCollection=genSched(teams, tau, events, phi, D, durations);

% build model
model.modelname = 'gymnastics';
model.modelsense = 'min';
    
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
result = gurobi(model)

while ~strcmp(result.status, 'OPTIMAL')
    % generate a new schedule and append to the collection
    schedCollection=[schedCollection,genSched(teams, tau, events, phi, D, durations)]

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
    
    % resolve model
    result = gurobi(model)
end

result.x

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
        % Max(F1 warm-up, F2 warm-up)+competition time
        checkEventsActivities=zeros(E,1);
        for e=1:E
            fac1WarmUp=0;
            fac2WarmUp=0;
            compTime=0;
            for t=1:T
                if t<=T/2
                    fac1WarmUp = fac1WarmUp + sched((t-1)*tau*E+e)*dur(e);
                else
                    fac2WarmUp = fac2WarmUp + sched((t-1)*tau*E+e)*dur(e);
                end
                compTime = compTime + sched((t-1)*tau*E+E+e)*dur(E+e);
            end

            if max(fac1WarmUp, fac2WarmUp)+compTime<=D
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