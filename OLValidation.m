% Expected Value Calculation
frontTyreMu = 1.64;
rearTyreMu = 1.74;
rTyre = 0.153;
vehicleMass = 280;

expectedRearTorque = 0.5 * vehicleMass * 9.81 * rearTyreMu * rTyre;
expectedFrontTorque = 0.5 * vehicleMass * 9.81 * frontTyreMu * rTyre;

% Process OL Data
rawOutput = readmatrix("straightOL.csv");
olOutput = [];

for i = 1:length(rawOutput)
    if rawOutput(i,15) > 0
        olOutput(end+1,:) = rawOutput(i,:);
    end
end

bpCol = olOutput(:,15);
speedCol = olOutput(:,1);
timeCol = olOutput(:,2);
distanceCol = olOutput(:, 3);
longAccelCol = olOutput(:,5);
crCol = olOutput(:,16);

possibleTorques = [];
for i = 1:length(olOutput)
    possibleTorques(end+1, 1) = (-1 * longAccelCol(i) * vehicleMass) * 0.153 / (bpCol(i)/100);
end

meanT = mean(possibleTorques);
minT = min(possibleTorques);
minTRear = 0.5 * minT * 1-rearTyreMu/frontTyreMu
minTFront = 0.5 * minT * 1+(rearTyreMu/frontTyreMu)

% Compare against expected values
totalExpected = expectedFrontTorque + expectedRearTorque;
totalSimulated = minTFront + minTRear;
totalDiff = totalExpected - totalSimulated;

fprintf("\nExpected front tyre torque:  " + expectedFrontTorque)
fprintf("\nSimulated front tyre torque: " + minTFront)
fprintf("\nExpected rear tyre torque:  " + expectedRearTorque)
fprintf("\nSimulated rear tyre torque: " + minTRear + "\n")
fprintf("\nExpected total tyre torque:  " + totalExpected)
fprintf("\nSimulated total tyre torque: " + totalSimulated + "\n")
fprintf("\nPercentage difference between expected and simulated values: " + (100*totalDiff/totalSimulated) + "%% \n")
