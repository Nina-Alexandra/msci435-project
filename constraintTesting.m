T=6;
E=4;
F=2;
slots=4;
durMinutes = [51,30,30,36];

c1Test = constraint1(slots, T, E, F, durMinutes);
c2Test = constraint2(slots, T, E);
c3Test = constraint3(slots, T, E);
c4Test = constraint4(slots, T, E, F);
c5Test = constraint5(slots, T, E);
c6Test = constraint6(slots, T, E);

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
