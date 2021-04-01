% setup gurobi for use with matlab
% https://www.gurobi.com/documentation/9.1/quickstart_mac/matlab_setting_up_grb_for_.html

%define primitive data
teams      = 12; % number of teams
tau        = 2; % number of activity types: warm-up and competition
events     = 4; % number of events: floor, vault, bars, beam
facilities = 2; % number of facilities
slots = 840; % set of time slots in a day (1 min/time slot - total time facility is open)

nTeamEngage = teams*tau*events*slots; % number of x decision variables
nBroadcasts = events*slots; % number of y decision variables
nTeamStarts = teams*tau*events*slots; % number of gamma decision variables

D   = 14;   % available facility time (total hours in a day facility is open)

durations = [45,25,25,30,6,6,6,6]; %  duration of each activity type (w1,w2,w3,w4,c1,c2,c3,c4) in # of slots/mins (rounded up)

% broadcastWeight = randi(10,events*slots,1); % broadcast weight for event e at timeslot s -> need to determine a logical weighting scheme 

%Set the broadcast weight values for each hour of the tournament 
h1 = 0;
h2 = 0;
h3 = 3;
h4 = 3;
h5 = 7;
h6 = 7;
h7 = 7;
h8 = 3;
h9 = 3;
h10 = 5;
h11 = 10;
h12 = 10;
h13 = 10;
h14 = 10;

%Set the broadcast weight values for each event
flWeight = 10;
vaWeight = 5;
baWeight = 7;
beWeight = 5;

broadcastWeight = [];

% i=1;
% for i=1:60
%     broadcastWeight(
% end

broadcastWeight(1:60,1)= repmat(h1+flWeight,60,1);
broadcastWeight(61:120,1)= repmat(h2+flWeight,60,1);
broadcastWeight(121:180,1)= repmat(h3+flWeight,60,1);
broadcastWeight(181:240,1)= repmat(h4+flWeight,60,1);
broadcastWeight(241:300,1)= repmat(h5+flWeight,60,1);
broadcastWeight(301:360,1)= repmat(h6+flWeight,60,1);
broadcastWeight(361:420,1)= repmat(h7+flWeight,60,1);
broadcastWeight(421:480,1)= repmat(h8+flWeight,60,1);
broadcastWeight(481:540,1)= repmat(h9+flWeight,60,1);
broadcastWeight(541:600,1)= repmat(h10+flWeight,60,1);
broadcastWeight(601:660,1)= repmat(h11+flWeight,60,1);
broadcastWeight(661:720,1)= repmat(h12+flWeight,60,1);
broadcastWeight(721:780,1)= repmat(h13+flWeight,60,1);
broadcastWeight(781:840,1)= repmat(h14+flWeight,60,1);

broadcastWeight(841:900,1)= repmat(h1+vaWeight,60,1);
broadcastWeight(901:960,1)= repmat(h2+vaWeight,60,1);
broadcastWeight(961:1020)= repmat(h3+vaWeight,60,1);
broadcastWeight(1021:1080,1)= repmat(h4+vaWeight,60,1);
broadcastWeight(1081:1140,1)= repmat(h5+vaWeight,60,1);
broadcastWeight(1141:1200,1)= repmat(h6+vaWeight,60,1);
broadcastWeight(1201:1260,1)= repmat(h7+vaWeight,60,1);
broadcastWeight(1261:1320,1)= repmat(h8+vaWeight,60,1);
broadcastWeight(1321:1380,1)= repmat(h9+vaWeight,60,1);
broadcastWeight(1381:1440,1)= repmat(h10+vaWeight,60,1);
broadcastWeight(1441:1500,1)= repmat(h11+vaWeight,60,1);
broadcastWeight(1501:1560,1)= repmat(h12+vaWeight,60,1);
broadcastWeight(1561:1620,1)= repmat(h13+vaWeight,60,1);
broadcastWeight(1621:1680,1)= repmat(h14+vaWeight,60,1);

broadcastWeight(1681:1740,1)= repmat(h1+baWeight,60,1);
broadcastWeight(1741:1800,1)= repmat(h2+baWeight,60,1);
broadcastWeight(1801:1860,1)= repmat(h3+baWeight,60,1);
broadcastWeight(1861:1920,1)= repmat(h4+baWeight,60,1);
broadcastWeight(1921:1980,1)= repmat(h5+baWeight,60,1);
broadcastWeight(1981:2040,1)= repmat(h6+baWeight,60,1);
broadcastWeight(2041:2100,1)= repmat(h7+baWeight,60,1);
broadcastWeight(2101:2160,1)= repmat(h8+baWeight,60,1);
broadcastWeight(2161:2220,1)= repmat(h9+baWeight,60,1);
broadcastWeight(2221:2280,1)= repmat(h10+baWeight,60,1);
broadcastWeight(2281:2340,1)= repmat(h11+baWeight,60,1);
broadcastWeight(2341:2400,1)= repmat(h12+baWeight,60,1);
broadcastWeight(2401:2460,1)= repmat(h13+baWeight,60,1);
broadcastWeight(2461:2520,1)= repmat(h14+baWeight,60,1);

broadcastWeight(2521:2580,1)= repmat(h1+beWeight,60,1);
broadcastWeight(2581:2640,1)= repmat(h2+beWeight,60,1);
broadcastWeight(2641:2700,1)= repmat(h3+beWeight,60,1);
broadcastWeight(2701:2760,1)= repmat(h4+beWeight,60,1);
broadcastWeight(2761:2820,1)= repmat(h5+beWeight,60,1);
broadcastWeight(2821:2880,1)= repmat(h6+beWeight,60,1);
broadcastWeight(2881:2940,1)= repmat(h7+beWeight,60,1);
broadcastWeight(2941:3000,1)= repmat(h8+beWeight,60,1);
broadcastWeight(3001:3060,1)= repmat(h9+beWeight,60,1);
broadcastWeight(3061:3120,1)= repmat(h10+beWeight,60,1);
broadcastWeight(3121:3180,1)= repmat(h11+beWeight,60,1);
broadcastWeight(3181:3240,1)= repmat(h12+beWeight,60,1);
broadcastWeight(3241:3300,1)= repmat(h13+beWeight,60,1);
broadcastWeight(3301:3360,1)= repmat(h14+beWeight,60,1);


% build model
model.modelname = 'gymnastics_model2';
model.modelsense = 'max';
    
% set data for variables
        %ncol = total number of columns in the A matrix 
        %(# of DVs = %164,640)
        %nrow = the total number of rows in the A matrix 
        ncol = nTeamsEngage + nBroadcasts + nTeamStarts;
        model.lb    = zeros(ncol, 1);
        model.ub    = ones(ncol, 1);
        model.obj   = broadcastWeight;
        model.vtype = repmat('B', ncol, 1);
        
    
% generate constraints
          model.A     = sparse(nrow, ncol); 
%         model.rhs   = TBD -> RHS value of the constraints 
          model.sense = [repmat('>=', numRowsC1, 1); repmat('>=', numRowsC2, 1); repmat('<=',numRowsC3,1); 
                        repmat('<=',numRowsC4,1); repmat('>=',numRowsC5,1); repmat('>=',numRowsC6,1);
                        repmat('>=',numRowsC7,1); repmat('<=',numRowsC8,1); repmat('<=',numRowsC9,1)];  % is >= and <= being represented properly?


%CONSTRAINT 1
%A matrix Dimension = 96x840 
numRowsC1 = teams*tau*events;
slotCounterEnd = slots;
slotCounterStart = 1;

for j = 1:numRowsC1
    model.A(j,slotCounterStart:slotCounterEnd) = ones(1,slots);
    slotCounterEnd = slotCounterEnd + slots;
    slotCounterStart = slotCounterStart + slots;
end      
      

RHS_c1 = repmat(transpose(durations),teams,1);
         
      
% !!!!CONSTRAINT 2 (TO DO)
%A matrix
    %Dimension = 96x840 
%RHS 
      RHS_c2 = zeros(80640,1);
      

%CONSTRAINT 3
%A matrix - Dimension = 10080x8 
numRowsC3 = teams*slots;

for m = %ROW TBC (based on C2):numRowsC3+numRowsC2+numRowsC1
    model.A(m,x_1111+x_1121+x_1131+ ) = ones(1,%corresponding w/up and comp slots for each team );
end      
      
RHS_c3 = ones(numRowsC3,1);
      
      
      
      
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
%A matrix - Dimension = 840X4 
%RHS 
numRowsC8 = slots; 
RHS_c3 = ones(numRowsC8,1); 
      
      
 
      
  %CONSTRAINT 9
%A matrix - Dimension = 3360x13 
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
