rng(42);

numSensors = 10;
samplingRate = 10;
maxTime = 10;
numSteps = samplingRate * maxTime;
dt = 1 / samplingRate;
stressThreshold = 80;
liveMode = false;

numSamples = 1000;
features = rand(numSamples, 3) * 100;
target = mean(features, 2) + randn(numSamples, 1) * 10;

cv = cvpartition(numSamples, 'HoldOut', 0.2);
XTrain = features(training(cv), :);
yTrain = target(training(cv));
XTest = features(test(cv), :);
yTest = target(test(cv));

treeTemplate = templateTree('MinLeafSize', 5);
model = fitrensemble(XTrain, yTrain, 'Method', 'Bag', ...
    'NumLearningCycles', 300, 'Learners', treeTemplate);

yPredTest = predict(model, XTest);
mseTest = mean((yPredTest - yTest).^2);
maeTest = mean(abs(yPredTest - yTest));
r2Test = 1 - sum((yTest - yPredTest).^2) / sum((yTest - mean(yTest)).^2);

fprintf('Hold-out performance of the stress prediction model\n');
fprintf('  MSE : %.2f kPa^2\n', mseTest);
fprintf('  MAE : %.2f kPa\n', maeTest);
fprintf('  R^2 : %.3f\n\n', r2Test);

sensorData = rand(numSensors, 3, numSteps) * 100;
time = (1:numSteps) * dt;
measured = reshape(mean(sensorData, 2), numSensors, numSteps);
predicted = zeros(numSensors, numSteps);

if liveMode
    liveFig = figure('Name', 'Digital twin live view');
    liveAx = axes(liveFig);
    hold(liveAx, 'on');
    grid(liveAx, 'on');
    xlabel(liveAx, 'Time (s)');
    ylabel(liveAx, 'Predicted stress (kPa)');
    title(liveAx, 'Digital twin: streaming stress prediction');
    yline(liveAx, stressThreshold, 'r--', 'Warning threshold');
end

for k = 1:numSteps
    current = sensorData(:, :, k);
    predicted(:, k) = predict(model, current);
    if liveMode
        plot(liveAx, repmat(time(k), numSensors, 1), predicted(:, k), 'b.');
        drawnow limitrate;
        pause(dt);
    end
end

[warnSensor, warnStep] = find(predicted > stressThreshold);
[warnStep, sortIdx] = sort(warnStep(:));
warnSensor = warnSensor(sortIdx);
warnTime = reshape(time(warnStep), [], 1);
warnStress = predicted(sub2ind(size(predicted), warnSensor, warnStep));
warningLog = [warnTime, warnSensor, warnStress];

warnings = array2table(warningLog, 'VariableNames', {'Time_s', 'Sensor', 'PredictedStress_kPa'});
fprintf('Warnings raised (predicted stress > %d kPa): %d\n', stressThreshold, height(warnings));
if ~isempty(warnings)
    disp(warnings);
end

streamMAE = mean(abs(predicted(:) - measured(:)));
fprintf('MAE between predicted and measured stress on the stream: %.2f kPa\n', streamMAE);

resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

fig1 = figure('Name', 'Model validation');
scatter(yTest, yPredTest, 18, 'filled', 'MarkerFaceAlpha', 0.6);
hold on;
lims = [min([yTest; yPredTest]), max([yTest; yPredTest])];
plot(lims, lims, 'k--');
grid on;
axis equal tight;
xlabel('Observed stress (kPa)');
ylabel('Predicted stress (kPa)');
title(sprintf('Hold-out parity plot (R^2 = %.3f)', r2Test));
exportgraphics(fig1, fullfile(resultsDir, 'parity_plot.png'), 'Resolution', 200);

fig2 = figure('Name', 'Digital twin monitoring', 'Position', [100 100 900 650]);
subplot(2, 1, 1);
plot(time, predicted', 'LineWidth', 0.8);
hold on;
yline(stressThreshold, 'r--', 'Warning threshold', 'LineWidth', 1.2, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
if ~isempty(warningLog)
    plot(warningLog(:, 1), warningLog(:, 3), 'rx', 'MarkerSize', 8, 'LineWidth', 1.2);
end
grid on;
xlabel('Time (s)');
ylabel('Predicted stress (kPa)');
title('Real-time stress prediction for all sensors');

subplot(2, 1, 2);
plot(1:numSensors, measured(:, end), 'r-o', 'DisplayName', 'Measured');
hold on;
plot(1:numSensors, predicted(:, end), 'b-o', 'DisplayName', 'Predicted');
grid on;
xlabel('Sensor');
ylabel('Stress (kPa)');
legend('Location', 'best');
title(sprintf('Measured vs predicted stress at t = %.1f s', time(end)));
exportgraphics(fig2, fullfile(resultsDir, 'digital_twin_monitoring.png'), 'Resolution', 200);

writetable(warnings, fullfile(resultsDir, 'warnings.csv'));
