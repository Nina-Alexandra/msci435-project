function bm = broadcastMatrix(numEpochs,numEvents)
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

    hourWeight = [h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,ones(1,numEpochs-14)];

    %Set the broadcast weight values for each event
    flWeight = 10;
    vaWeight = 5;
    baWeight = 7;
    beWeight = 5;

    broadcastWeight = zeros(numEpochs,numEvents);

    for i = 1:numEpochs
        broadcastWeight(i,1) = hourWeight(1,i) + flWeight;
        broadcastWeight(i,2) = hourWeight(1,i) + vaWeight;
        broadcastWeight(i,3) = hourWeight(1,i) + baWeight;
        broadcastWeight(i,4) = hourWeight(1,i) + beWeight;
    end

    bm = broadcastWeight;
end