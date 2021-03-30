% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

%define primitive data
teams      = 12; % number of teams
tau        = 2; % number of activity types: warm-up and competition
events     = 4; % number of events: floor, vault, bars, beam
facilities = 2; % number of facilities
slots = 840; % set of time slots in a day (1 min/time slot - total time facility is open)

nTeamEngage = tau*teams*slots*events; % number of x decision variables
nTeamStarts = tau*teams*slots*events; % number of gamma decision variables
nBroadcasts = slots*events; % number of y decision variables

D   = 14;   % available facility time (total hours in a day facility is open)

durations = [45,25,25,30,6,6,6,6]; %  duration of each activity type (w1,w2,w3,w4,c1,c2,c3,c4) in # of slots/mins (rounded up)

broadcastWeight = randi(10,events*slots,1); % broadcast weight for event e at timeslot s -> need to determine a logical weighting scheme 

% build model
model.modelname = 'gymnastics_model2';
model.modelsense = 'max';
    
% set data for variables
        %ncol = value of the largest width of the constraints
        %nrow = the total number of rows in the A matrix 
        ncol = nTeamsEngage + nTeamStarts + nBroadcasts;
        model.lb    = zeros(ncol, 1);
        model.ub    = ones(ncol, 1);
        model.obj   = broadcastWeight;
        model.vtype = repmat('B', ncol, 1);
        
    
% generate constraints
          model.A     = sparse(nrow, ncol); 
%         model.rhs   = TBD -> RHS value of the constraints 
          model.sense = [repmat('>=', RHS_c1, 1); repmat('>=', RHS_c2, 1); repmat('<=',RHS_c3,1); 
                        repmat('<=',RHS_c4,1); repmat('>=',RHS_c5,1); repmat('>=',RHS_c6,1);
                        repmat('>=',RHS_c7,1); repmat('<=',RHS_c8,1); repmat('<=',RHS_c9,1)]; % indicating that the obj is to minimize?
                % is >= and <= being represented properly?


%CONSTRAINT 1
%A matrix
    %Dimension = 96x840 
    %coefficients are 1 or 0... dependent on the schedule output from model
    %1
%RHS 
      RHS_c1 = repmat(transpose(durations),teams,1);
      
      
% !!!!CONSTRAINT 2 (TO DO)
%A matrix
    %Dimension = 96x840 
%RHS 
      RHS_c2 = zeros(80640,1);
      

%CONSTRAINT 3
%A matrix
    %Dimension = 10080x8 
%RHS 
      RHS_c3 = ones(10080,1);
      
      
 %CONSTRAINT 4
%A matrix
    %Dimension = 6720x24
%RHS 
      RHS_c4 = ones(6720,1);
      
      
% !!!!CONSTRAINT 5 (TO DO)
%A matrix
    %Dimension = 96x840 
%RHS 
      RHS_c5 = repmat(transpose(durations),12,1);
      
      
% !!!!CONSTRAINT 6 (TO DO)
%A matrix
    %Dimension = 96x840 
%RHS 
      RHS_c6 = repmat(transpose(durations),12,1);
      
      
% !!!!CONSTRAINT 7 (TO DO)
%A matrix
    %Dimension = 96x840 
%RHS 
      RHS_c7 = repmat(transpose(durations),12,1);
     
      
      
  %CONSTRAINT 8
%A matrix
    %Dimension = 840X4 
%RHS 
      RHS_c8 = ones(840,1);
      
      
  %CONSTRAINT 9
%A matrix
    %Dimension = 3360x13 
    %col 1 - 12 relates to DV x, col 13 is DV y
%RHS 
      RHS_c9 = zeros(3360,1);


   
      
      
      




% fill A matrix
% for rows s  1 to 64, 
for s=1:schedSize
    model.A(s,1) = schedCollection(s,1);
end

% solve model
result = gurobi(model);


function gt = genTimetable(T, tau, E, phi, D, dur)

    valid = false;
    v1=0;
    v2=0;
    %each schedule starts unvalidated 
    while valid == false
        % generate a random schedule
        % https://www.mathworks.com/matlabcentral/answers/111540-generating-a-random-binary-matrix
        shortSched = randi([0 1],E,1); %short schedule just being of the length of the event  
        
        sched = repmat(shortSched,T*tau,1); %this is repeating the column vector/ schedule, which has values
        % of 0 or 1, of length = to #teams *2 (but also indirectly
        % multiplied by the # of events (being 4)

        
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
        
        %If v1=1, it passes the first test 
       
        
        % An event’s activities in a day can’t exceed the available facility time
        % Max(F1 warm-up, F2 warm-up)+competition time
        checkEventsActivities=zeros(E,1); %vector of 0s that is 4x1
        
        %for each of the 4 events, set the warm-up time and compTime to be 0 in each
        %facility 
        for e=1:E
            fac1WarmUp=0;
            fac2WarmUp=0;
            compTime=0;
            
            %for each of the teams, if the team number is btw 1-4 assign
            %them to facility 1, or else, if team 5-8 assign to facility 2
   %having a hard time understanding this code/constraint
   %completely 
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





%constraints in pseudo code 

%constraint 1
    %for time slot 1 to 840, the sum of DV x needs to be greater than the
    %duration of every given team/activity pair 
    
    
    
 %constraint 2
    %????
    
    
  %constraint 3
  
     %the sum of all activity events being on for a given team is less than
     %or equal to 1
     
  %constraint 4
  
    %for all the events in a facility, it can only be used by one team for a given event activity at once 
    
    
   %constraint 5 
   
        %All teams must complete in an event consecutively (τ=2) ???
        
   %constraint 6 
        %repeating constraint 5, but for competition events 
        
        
        
   %constraint 7 
       %the slot of the warm-up needs to be before the slot of the
       %competition for all of the teams and events 
       
       
       
   %constraint 8 
       % only broadcast one event at a time 
       
       
       
   %only broadcast if there is a competition occurring at time s (no need
   %to broadcast warmups)


% while ~strcmp(result.status, 'OPTIMAL')
%     % generate a new schedule and append to the collection
%     schedCollection=[schedCollection,genSched(teams, tau, events, phi, D, durations)]
% 
%     % update data for variables
%     ncol = ncol + 1;
%     model.lb    = [model.lb; 0];
%     model.ub    = [model.ub; 1];
%     model.obj   = [model.obj; 1];
%     model.vtype = [model.vtype; 'B'];
%     
%     % update constraints
%     model.A = sparse(schedSize, ncol);
%     
%     for s=1:schedSize
%         for h=1:ncol
%             model.A(s,h) = schedCollection(s,h);
%         end
%     end
%     
%     % resolve model
%     result = gurobi(model)
% end
% 
% result.x
% 
% %was there a reasons some of these var names have been renamed for the
% %genSched function? 
% function gs = genSched(T, tau, E, phi, D, dur)
%     valid = false;
%     v1=0;
%     v2=0;
%     %each schedule starts unvalidated 
%     while valid == false
%         % generate a random schedule
%         % https://www.mathworks.com/matlabcentral/answers/111540-generating-a-random-binary-matrix
%         shortSched = randi([0 1],E,1); %short schedule just being of the length of the event  
%         
%         sched = repmat(shortSched,T*tau,1); %this is repeating the column vector/ schedule, which has values
%         % of 0 or 1, of length = to #teams *2 (but also indirectly
%         % multiplied by the # of events (being 4)
% 
%         
%         % validate the schedule
%         % A team’s activities in a day can’t exceed phi*D
%         checkTeamsActivities=zeros(T,1);
%         for t=1:T
%             if sched((t-1)*tau*E+1:t*tau*E).'*dur<=phi*D
%                 checkTeamsActivities(t)=1;
%             end
%         end
%         if sum(checkTeamsActivities)==T
%             v1=1;
%         end
%         
%         %If v1=1, it passes the first test 
%        
%         
%         % An event’s activities in a day can’t exceed the available facility time
%         % Max(F1 warm-up, F2 warm-up)+competition time
%         checkEventsActivities=zeros(E,1); %vector of 0s that is 4x1
%         
%         %for each of the 4 events, set the warm-up time and compTime to be 0 in each
%         %facility 
%         for e=1:E
%             fac1WarmUp=0;
%             fac2WarmUp=0;
%             compTime=0;
%             
%             %for each of the teams, if the team number is btw 1-4 assign
%             %them to facility 1, or else, if team 5-8 assign to facility 2
%    %having a hard time understanding this code/constraint
%    %completely 
%             for t=1:T
%                 if t<=T/2
%                     fac1WarmUp = fac1WarmUp + sched((t-1)*tau*E+e)*dur(e);
%                 else
%                     fac2WarmUp = fac2WarmUp + sched((t-1)*tau*E+e)*dur(e);
%                 end
%                 compTime = compTime + sched((t-1)*tau*E+E+e)*dur(E+e);
%             end
% 
%             if max(fac1WarmUp, fac2WarmUp)+compTime<=D
%                 checkEventsActivities(e)=1;
%             end
%         end
%         if sum(checkEventsActivities)==E
%             v2=1;
%         end
% 
%         % If all tests pass then add sched to schedCollection
%         if (v1+v2)==2
%             valid=true;
%         end
%     end
%     gs = sched;
% end
