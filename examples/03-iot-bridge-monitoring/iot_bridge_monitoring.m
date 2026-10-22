rng(42);

numSensors = 10;
duration = 60;
dt = 1;
numSteps = duration / dt;
time = (1:numSteps) * dt;

strainThreshold = 300;
tiltThreshold = 5;
vibrationThreshold = 0.5;
persistence = 3;
liveMode = false;

strain = randn(numSensors, numSteps) * 50 + 150;
tilt = rand(numSensors, numSteps) * 10;
vibration = rand(numSensors, numSteps) * 0.8;

strainExceed = strain > strainThreshold;
tiltExceed = tilt > tiltThreshold;
vibrationExceed = vibration > vibrationThreshold;

if liveMode
    liveFig = figure('Name', 'IoT live monitoring');
    for k = 1:numSteps
        clf(liveFig);
        subplot(3, 1, 1);
        plot(1:numSensors, strain(:, k), 'r-o');
        yline(strainThreshold, 'r--');
        ylabel('Strain (\mu\epsilon)');
        title(sprintf('t = %d s', time(k)));
        grid on;
        subplot(3, 1, 2);
        plot(1:numSensors, tilt(:, k), 'g-o');
        yline(tiltThreshold, 'g--');
        ylabel('Tilt (deg)');
        grid on;
        subplot(3, 1, 3);
        plot(1:numSensors, vibration(:, k), 'b-o');
        yline(vibrationThreshold, 'b--');
        ylabel('Vibration (g)');
        xlabel('Sensor');
        grid on;
        drawnow;
        pause(0.5);
    end
end

rawWarnings = [sum(strainExceed, 2), sum(tiltExceed, 2), sum(vibrationExceed, 2)];
sustainedAlarms = [sustainedEvents(strainExceed, persistence), ...
                   sustainedEvents(tiltExceed, persistence), ...
                   sustainedEvents(vibrationExceed, persistence)];

summary = table((1:numSensors)', rawWarnings(:, 1), rawWarnings(:, 2), rawWarnings(:, 3), ...
    sustainedAlarms(:, 1), sustainedAlarms(:, 2), sustainedAlarms(:, 3), ...
    'VariableNames', {'Sensor', 'StrainWarnings', 'TiltWarnings', 'VibrationWarnings', ...
    'StrainAlarms', 'TiltAlarms', 'VibrationAlarms'});
disp(summary);
fprintf('Total single-sample warnings: %d\n', sum(rawWarnings(:)));
fprintf('Total sustained alarms (>= %d consecutive samples): %d\n', persistence, sum(sustainedAlarms(:)));

resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

fig1 = figure('Name', 'Sensor streams', 'Position', [100 100 900 700]);
subplot(3, 1, 1);
plot(time, strain');
yline(strainThreshold, 'r--', 'Threshold', 'LineWidth', 1.2);
ylabel('Strain (\mu\epsilon)');
title('Strain');
grid on;
subplot(3, 1, 2);
plot(time, tilt');
yline(tiltThreshold, 'r--', 'Threshold', 'LineWidth', 1.2);
ylabel('Tilt (deg)');
title('Tilt');
grid on;
subplot(3, 1, 3);
plot(time, vibration');
yline(vibrationThreshold, 'r--', 'Threshold', 'LineWidth', 1.2);
ylabel('Vibration (g)');
xlabel('Time (s)');
title('Vibration');
grid on;
exportgraphics(fig1, fullfile(resultsDir, 'sensor_streams.png'), 'Resolution', 200);

fig2 = figure('Name', 'Warnings and alarms', 'Position', [100 100 900 600]);
subplot(2, 1, 1);
bar(1:numSensors, rawWarnings, 'stacked');
xlabel('Sensor');
ylabel('Count');
title('Single-sample threshold exceedances');
legend('Strain', 'Tilt', 'Vibration', 'Location', 'eastoutside');
grid on;
subplot(2, 1, 2);
bar(1:numSensors, sustainedAlarms, 'grouped');
xlabel('Sensor');
ylabel('Count');
title(sprintf('Sustained alarms (>= %d consecutive exceedances)', persistence));
legend('Strain', 'Tilt', 'Vibration', 'Location', 'eastoutside');
grid on;
exportgraphics(fig2, fullfile(resultsDir, 'warnings_and_alarms.png'), 'Resolution', 200);

writetable(summary, fullfile(resultsDir, 'warning_summary.csv'));

function events = sustainedEvents(exceed, minLength)
events = zeros(size(exceed, 1), 1);
for i = 1:size(exceed, 1)
    edges = diff([0, double(exceed(i, :)), 0]);
    starts = find(edges == 1);
    stops = find(edges == -1);
    events(i) = sum((stops - starts) >= minLength);
end
end
