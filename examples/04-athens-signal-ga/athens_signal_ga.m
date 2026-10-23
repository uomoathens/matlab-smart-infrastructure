rng(42);

here = fileparts(mfilename('fullpath'));
data = readtable(fullfile(here, 'data', 'athens_traffic.csv'), 'TextType', 'string');
disp(data);

flows = data.flow';
speeds = data.speed';
occupancies = data.occupancy';
numLights = height(data);

lb = 10 * ones(1, numLights);
ub = 120 * ones(1, numLights);

weights = occupancies ./ (speeds + 1);
fitness = @(g) sum(g .* weights) + sum(flows ./ (g + 1));

options = optimoptions('ga', ...
    'Display', 'final', ...
    'PopulationSize', 100, ...
    'MaxGenerations', 300, ...
    'CreationFcn', @gacreationuniform, ...
    'CrossoverFcn', @crossoverscattered, ...
    'SelectionFcn', @selectionstochunif, ...
    'MutationFcn', @mutationadaptfeasible, ...
    'HybridFcn', @fmincon);

[greenGA, fitnessGA] = ga(fitness, numLights, [], [], [], [], lb, ub, [], options);

greenExact = min(max(sqrt(flows ./ weights) - 1, lb), ub);
fitnessExact = fitness(greenExact);

results = table(data.location, greenGA', greenExact', abs(greenGA' - greenExact'), ...
    'VariableNames', {'Location', 'GreenGA_s', 'GreenClosedForm_s', 'AbsDifference_s'});
disp(results);
fprintf('Fitness (GA + fmincon): %.6f\n', fitnessGA);
fprintf('Fitness (closed form) : %.6f\n', fitnessExact);
fprintf('Max deviation from closed-form optimum: %.2e s\n', max(results.AbsDifference_s));

resultsDir = fullfile(here, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

locationLabels = strrep(data.location, '_', ' ');

fig = figure('Name', 'Athens signal optimisation', 'Position', [100 100 900 480]);
tl = tiledlayout(fig, 1, 1, 'Padding', 'compact');
ax = nexttile(tl);
b = bar(ax, 1:numLights, [greenGA', greenExact'], 'grouped');
xticks(ax, 1:numLights);
xticklabels(ax, locationLabels);
b(1).FaceColor = [0 0.5 0];
b(2).FaceColor = [0.6 0.8 0.6];
text(ax, b(1).XEndPoints, b(1).YEndPoints, compose('%.2f', greenGA), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
text(ax, b(2).XEndPoints, b(2).YEndPoints, compose('%.2f', greenExact), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
ylim(ax, [0 15]);
ylabel(ax, 'Green light duration (s)');
title(ax, 'Optimal green durations: genetic algorithm vs closed-form optimum', 'FontWeight', 'normal');
legend(ax, 'GA + fmincon', 'Closed form', 'Location', 'northoutside', 'Orientation', 'horizontal');
grid(ax, 'on');
exportgraphics(fig, fullfile(resultsDir, 'green_durations.png'), 'Resolution', 200);

writetable(results, fullfile(resultsDir, 'green_durations.csv'));
