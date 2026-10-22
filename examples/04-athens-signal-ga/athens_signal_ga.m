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

locationLabels = categorical(strrep(data.location, '_', ' '));
locationLabels = reordercats(locationLabels, cellstr(strrep(data.location, '_', ' ')));

fig = figure('Name', 'Athens signal optimisation');
b = bar(locationLabels, [greenGA', greenExact'], 'grouped');
b(1).FaceColor = [0 0.5 0];
b(2).FaceColor = [0.6 0.8 0.6];
ylabel('Green light duration (s)');
title('Optimal green durations: genetic algorithm vs closed-form optimum');
legend('GA + fmincon', 'Closed form', 'Location', 'eastoutside');
grid on;
exportgraphics(fig, fullfile(resultsDir, 'green_durations.png'), 'Resolution', 200);

writetable(results, fullfile(resultsDir, 'green_durations.csv'));
