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

fig = figure('Name', 'Wastewater Pareto front', 'Position', [100 100 1100 460]);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'loose', 'Padding', 'compact');

ax1 = nexttile(tl);
plot(ax1, fval(:, 1), fval(:, 2), 'o', 'Color', [0.8 0.2 0.2]);
hold(ax1, 'on');
plot(ax1, fval(compromiseIdx, 1), fval(compromiseIdx, 2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
xlabel(ax1, 'Total cost');
ylabel(ax1, 'Environmental impact');
title(ax1, 'Pareto front');
legend(ax1, 'Pareto-optimal designs', 'Compromise design', 'Location', 'northeast', 'Box', 'off');
grid(ax1, 'on');

ax2 = nexttile(tl);
scatter(ax2, x(:, 1), x(:, 2), 30, fval(:, 1), 'filled');
hold(ax2, 'on');
x1Line = linspace(lb(1), ub(1), 100);
hLimit = plot(ax2, x1Line, (requiredCapacity - capacityCoeffs(1) * x1Line) / capacityCoeffs(2), 'k--');
hStar = plot(ax2, x(compromiseIdx, 1), x(compromiseIdx, 2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
xlim(ax2, [lb(1) ub(1)]);
ylim(ax2, [lb(2) ub(2)]);
cb = colorbar(ax2);
cb.Title.String = 'Total cost';
xlabel(ax2, 'Primary unit size');
yl = ylabel(ax2, 'Secondary unit size');
yl.Units = 'normalized';
yl.Position(1) = -0.14;
title(ax2, 'Pareto set in design space (colour: total cost)');
legend(ax2, [hLimit, hStar], {'Capacity limit', 'Compromise design'}, 'Location', 'southwest', 'Box', 'off');
grid(ax2, 'on');
exportgraphics(fig, fullfile(resultsDir, 'pareto_front.png'), 'Resolution', 200);

writetable(pareto, fullfile(resultsDir, 'pareto_front.csv'));

function f = wastewaterObjectives(x)
constructionCost = 7000 * x(1)^0.6 + 9000 * x(2)^0.65;
operationalCost = 100 * x(1)^0.8 + 150 * x(2)^0.85;
environmentalImpact = 250 * x(1)^-0.7 + 350 * x(2)^-0.75;
f = [constructionCost + operationalCost, environmentalImpact];
end
