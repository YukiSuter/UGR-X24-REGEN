%filename = "continuous.csv"; frontRearBrakeSplit = 0.723; maxCellChargeCurrent = 26.4; tsEfficiency = 0.9; accVoltage = 583;

function out = EnergyEstimation(filename, frontRearBrakeSplit, maxCellChargeCurrent, tsEfficiency, accVoltage)
    maxMotorTorque = 6.79856115107913; % Taking minMaxTorque (the lowest max torque)
    filename = "csvs\" + filename;
    AMKTorqueData = readmatrix('Orange Torque.csv');
    AMKPowerData = readmatrix('Orange Power.csv');
    rawOLData =  textread(filename, '%s','delimiter', '\n');
    OLData = readmatrix(filename);
    
    OLDataName = strsplit(rawOLData{2}, ','); OLDataName = strcat(OLDataName{2}," ", OLDataName{3});
    gearRatio = strsplit(rawOLData{43}, ","); gearRatio = str2double(gearRatio{2});
    weight = strsplit(rawOLData{32}, ","); weight = str2double(weight{2}) * 9.81;
    muLong = strsplit(rawOLData{41}, ","); muLong = str2double(muLong{2});
    rTyre = strsplit(rawOLData{38}, ","); rTyre = str2double(rTyre{2});

    maxBrakeTorque = weight * muLong * rTyre
    
    maxRegenTorque = gearRatio * maxMotorTorque;
    frontBrakeTorque = maxBrakeTorque * frontRearBrakeSplit;
    rearBrakeTorque = maxBrakeTorque * (1-frontRearBrakeSplit)/2;
    
    timeArray = OLData(:, 2);
    mSpeedArray = OLData(:,8);
    bTorqueArray = OLData(:,15) .* rearBrakeTorque / 100;
    
    % Torque vs Time Graph
    
    maxRTorqueArray = zeros(length(timeArray), 1) + maxRegenTorque; % An array filled with the maxRegenTorque figure
    [c index] = min(abs((AMKTorqueData(:,1))-mSpeedArray')); % match the torque on the graph with the rpm of the vehicle
    closestTorqueArray = AMKTorqueData(index, 2) .* gearRatio; % An array of these matched torque values
    
    plot(timeArray, bTorqueArray)
    line(timeArray, maxRTorqueArray)
    line(timeArray, closestTorqueArray)
    ylabel('Torque [Nm]')
    xlabel('Time [s]')
    title(strcat(OLDataName , ' - Torque Time'))
    legend('Total Brake Torque','Minimum Max Regen Torque', 'Dynamic Max Regen Torque')
    
    saveas(gcf, strcat("output\", OLDataName, ' torque_time.png'))
    
    % I_charge vs time (Assuming linear)
    
    [c index] = min(abs((AMKPowerData(:,1))-mSpeedArray')); % match the power on the graph with the rpm of the vehicle
    closestPowerArray = AMKPowerData(index, 2)*1000; % An array of matched power values
    closestCurrentArray = closestPowerArray / accVoltage .* 2; % The current value, multiplied by 2 for the 2 rear wheels
    
    expectedCurrentArray = min(closestCurrentArray .* (bTorqueArray./maxRTorqueArray), closestCurrentArray) .* tsEfficiency; % Find the expected current by using the torque values or the closestcurrent array whichever is smaller
    expectedCurrentLimitedArray = min(expectedCurrentArray, min(closestCurrentArray, maxCellChargeCurrent)); % Same as above but current limited to the charging current
    
    maxChargeCurrent = zeros(length(timeArray), 1) + maxCellChargeCurrent;
    
    plot(timeArray, closestCurrentArray)
    line(timeArray, expectedCurrentArray)
    line(timeArray, expectedCurrentLimitedArray)
    line(timeArray, maxChargeCurrent)
    legend('Max regen current possible', 'Max regen charging current', 'Limited regen charging current', 'Max charge current of cells')
    xlabel('Time [s]')
    ylabel('Current [a]')
    title(strcat(OLDataName , ' - Current Time'))
    saveas(gcf, strcat("output\", OLDataName , ' current_time.png'))
    
    % Realistic regen charging current
    
    plot(timeArray, expectedCurrentLimitedArray)
    legend('Realistic max charging')
    xlabel('Time [s]')
    ylabel('Current [a]')
    title(strcat(OLDataName , ' - Realistic Current Time'))
    saveas(gcf, strcat("output\", OLDataName , ' real_current_time.png'))

    % Power use graph

    plot(timeArray, (OLData(:, 10)))
    legend("Power usage")
    xlabel("Time [s]")
    ylabel("Power [kW]")
    title(strcat(OLDataName , ' - Power Time'))
    saveas(gcf, strcat("output\", OLDataName , ' power_time.png'))

    % Calculate max torque from realistic regen

    maxPowerAcceptable = accVoltage * maxCellChargeCurrent/1000/2;
    powerAtMaxRPM = AMKPowerData(length(AMKPowerData), 2);
    maxRegenTorqueAcceptable = maxPowerAcceptable/powerAtMaxRPM * maxRegenTorque;
    
    % Overall charge regenerated
    %hpToW = OLData(:, 10) * 0.7457 * 1000;
    totalPowerRequired = trapz(timeArray, OLData(:, 10))*1000/3600;
    
    "Total power used over a lap of FSAustria 2012: " + totalPowerRequired + "Wh"
    
    A = [timeArray expectedCurrentLimitedArray];
    totalRegenLimited = trapz(A(:,1), A(:,2))*accVoltage/3600;
    
    "Total regen (limited) over FSAustria 2012: " + totalRegenLimited + "Wh"
    
    A = [timeArray expectedCurrentArray];
    totalRegenLimitless = trapz(A(:,1), A(:,2))*accVoltage/3600;
    
    "Total regen (unlimited) over FSAustria 2012: " + totalRegenLimitless + "Wh"
    
    outlabels = ["maxAcceptableRegenTorque", "powerUsed", "expectedRegen", "limitlessRegen"];
    outdata = [maxRegenTorqueAcceptable, totalPowerRequired, totalRegenLimited, totalRegenLimitless];
        
    out = dictionary(outlabels, outdata);
end




