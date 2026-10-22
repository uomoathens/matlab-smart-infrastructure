rng(42);

nvars = 2;
lb = [100, 100];
ub = [1000, 1000];

capacityCoeffs = [1.2, 1.5];
requiredCapacity = 1500;
A = -capacityCoeffs;
b = -requiredCapacity;

options = optimoptions('gamultiobj', ...
    'PopulationSize', 200, ...
    'MaxGenerations', 100, ...
    'FunctionTolerance', 1e-4, ...
    'Display', 'final');

[x, fval] = gamultiobj(@wastewaterObjectives, nvars, A, b, [], [], lb, ub, [], options);

[~, order] = sort(fval(:, 1));
x = x(order, :);
fval = fval(order, :);
capacity = x * capacityCoeffs';

normalised = (fval - min(fval)) ./ (max(fval) - min(fval));
[~, compromiseIdx] = min(vecnorm(normalised, 2, 2));

pareto = table(x(:, 1), x(:, 2), capacity, fval(:, 1), fval(:, 2), ...
    'VariableNames', {'PrimaryUnitSize', 'SecondaryUnitSize', 'Capacity', ...
    'TotalCost', 'EnvironmentalImpact'});

fprintf('Pareto-optimal designs found: %d\n', height(pareto));
fprintf('Primary unit range  : %.0f to %.0f\n', min(x(:, 1)), max(x(:, 1)));
fprintf('Secondary unit range: %.0f to %.0f\n', min(x(:, 2)), max(x(:, 2)));
fprintf('Minimum capacity: %.2f (required %d)\n', min(capacity), requiredCapacity);
fprintf('\nCompromise design (closest to the utopia point):\n');
disp(pareto(compromiseIdx, :));

resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

fig = figure('Name', 'Wastewater Pareto front', 'Position', [100 100 1000 420]);
subplot(1, 2, 1);
plot(fval(:, 1), fval(:, 2), 'o', 'Color', [0.8 0.2 0.2]);
hold on;
plot(fval(compromiseIdx, 1), fval(compromiseIdx, 2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
xlabel('Total cost');
ylabel('Environmental impact');
title('Pareto front');
legend('Pareto-optimal designs', 'Compromise design', 'Location', 'northeast');
grid on;

subplot(1, 2, 2);
scatter(x(:, 1), x(:, 2), 30, fval(:, 1), 'filled');
hold on;
x1Line = linspace(lb(1), ub(1), 100);
plot(x1Line, (requiredCapacity - capacityCoeffs(1) * x1Line) / capacityCoeffs(2), 'k--');
plot(x(compromiseIdx, 1), x(compromiseIdx, 2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
xlim([lb(1) ub(1)]);
ylim([lb(2) ub(2)]);
cb = colorbar;
cb.Label.String = 'Total cost';
xlabel('Primary unit size');
ylabel('Secondary unit size');
title('Pareto set in design space');
legend('Pareto-optimal designs', 'Capacity limit', 'Compromise design', 'Location', 'southwest');
grid on;
exportgraphics(fig, fullfile(resultsDir, 'pareto_front.png'), 'Resolution', 200);

writetable(pareto, fullfile(resultsDir, 'pareto_front.csv'));

function f = wastewaterObjectives(x)
constructionCost = 7000 * x(1)^0.6 + 9000 * x(2)^0.65;
operationalCost = 100 * x(1)^0.8 + 150 * x(2)^0.85;
environmentalImpact = 250 * x(1)^-0.7 + 350 * x(2)^-0.75;
f = [constructionCost + operationalCost, environmentalImpact];
end
