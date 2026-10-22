rng(42);

features = [15, 0.30, 0.80;
            17, 0.25, 0.85;
            22, 0.80, 1.50;
            19, 0.70, 1.20;
            16, 0.35, 0.90;
            23, 0.90, 1.60;
            18, 0.40, 1.00;
            24, 1.00, 1.70;
            14, 0.20, 0.70;
            21, 0.75, 1.40;
            20, 0.65, 1.30;
            16, 0.38, 0.95;
            19, 0.50, 1.10];

labelCodes = [1; 1; 0; 0; 1; 0; 1; 0; 1; 0; 0; 1; 1];
labels = categorical(labelCodes, [0 1], {'Damaged', 'Healthy'});
numObs = numel(labels);

ensembleModel = fitcensemble(features, labels, 'Method', 'Bag', 'NumLearningCycles', 100);
networkModel = fitcnet(features, labels, 'LayerSizes', 10, 'Activations', 'relu', ...
    'Standardize', true, 'IterationLimit', 1000);

ensembleResubAcc = 100 * (1 - resubLoss(ensembleModel));
networkResubAcc = 100 * (1 - resubLoss(networkModel));

looPartition = cvpartition(numObs, 'LeaveOut');
ensembleCV = fitcensemble(features, labels, 'Method', 'Bag', 'NumLearningCycles', 100, ...
    'CVPartition', looPartition);
networkCV = fitcnet(features, labels, 'LayerSizes', 10, 'Activations', 'relu', ...
    'Standardize', true, 'IterationLimit', 1000, 'CVPartition', looPartition);

ensembleLooPred = kfoldPredict(ensembleCV);
networkLooPred = kfoldPredict(networkCV);
ensembleLooAcc = 100 * mean(ensembleLooPred == labels);
networkLooAcc = 100 * mean(networkLooPred == labels);

summary = table({'Bagged trees'; 'Neural network'}, ...
    [ensembleResubAcc; networkResubAcc], [ensembleLooAcc; networkLooAcc], ...
    'VariableNames', {'Model', 'TrainingAccuracy_pct', 'LeaveOneOutAccuracy_pct'});
disp(summary);

predictions = table(labels, ensembleLooPred, networkLooPred, ...
    'VariableNames', {'Actual', 'BaggedTrees_LOO', 'NeuralNetwork_LOO'});
disp(predictions);

resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

fig = figure('Name', 'SHM classification', 'Position', [100 100 900 380]);
tiledlayout(fig, 1, 2);
nexttile;
confusionchart(labels, ensembleLooPred, 'Title', sprintf('Bagged trees, LOO accuracy %.1f%%', ensembleLooAcc));
nexttile;
confusionchart(labels, networkLooPred, 'Title', sprintf('Neural network, LOO accuracy %.1f%%', networkLooAcc));
exportgraphics(fig, fullfile(resultsDir, 'confusion_matrices.png'), 'Resolution', 200);

writetable(summary, fullfile(resultsDir, 'accuracy_summary.csv'));
