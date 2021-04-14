[bestSched, bestDays] = project_part1_SetCovering(5);
for iter=1:10
    %disp(['Solving Instance ' num2str(iter)]);
    [sched, nDays] = project_part1_SetCovering(5);
    if nDays < bestDays
        bestSched = sched;
        bestDays = nDays;
    end
end

disp(bestSched);