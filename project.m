% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

teams      = 8; % number of teams
tau        = 2; % number of activity types: warm-up and competition
events     = 4; % number of events: floor, vault bars, beam
facilities = 2; % number of facilities

D   = 16;   % available facility time (total facility hours in a day)
phi = 0.8;  % the percent of D during which a team can be active

% the duration of the activity of type τ (row) for event e (col) for a single team
durations = [0; 0; 0; 0; 0; 0; 0; 0];
    
schedSize = teams*tau*events;

schedCollection=[];

for h=1:3
    schedCollection(1:schedSize,h)=genSched(schedSize, teams, tau, events, phi, D, durations);
end

function gs = genSched(sSize, T, tau, E, phi, D, dur)
    valid = false;
    v1=0;
    v2=0;
    v3=0;
    v4=0;
    while valid == false
        % generate a random schedule
        % https://www.mathworks.com/matlabcentral/answers/111540-generating-a-random-binary-matrix
        sched = randi([0 1],sSize,1);

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

        % Warm-up and competition for the same event must happen on the same day
        checkWarmUpAndComp=zeros(T,E);
        for t=1:T
            for e=1:E
                if sched((t-1)*tau*E+e)==sched((t-1)*tau*E+E+e)
                    checkWarmUpAndComp(t,e)=1;
                end
            end
        end
        if sum(checkWarmUpAndComp)==T*E
            v3=1;
        end
        
        % If one team competes in an event on a day, then all teams compete in that
        % event on that day
        checkAllOrNoneCompete=zeros(E,1);
        for e=1:E
            numCompeting=0;
            for t=1:T
                numCompeting=numCompeting+sched((t-1)*tau*E+E+e);
            end
            if numCompeting==0 || numCompeting==T
                checkAllOrNoneCompete(e)=1;
            end
        end
        if sum(checkAllOrNoneCompete)==E
            v4=1;
        end

        % If all tests pass then add sched to schedCollection
        if (v1+v2+v3+v4)==4
            valid=true;
        end
    end
    gs = sched;
end