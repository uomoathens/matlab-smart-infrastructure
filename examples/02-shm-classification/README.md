# 02 · Structural health classification

Book section 15.6.1.

Binary classification of structures as *Healthy* or *Damaged* from three sensor-derived indicators, comparing a bagged ensemble of decision trees with a shallow neural network (one hidden layer of 10 ReLU units, softmax output).

## Model

- Feature standardisation: $z = (x-\mu)/\sigma$
- Softmax output: $\sigma(z_i) = e^{z_i} / \sum_{j=1}^{K} e^{z_j}$
- Accuracy: correct predictions divided by total predictions, times 100

## Evaluation

The script reports two figures for each model:

1. **Training accuracy**, as in the book.
2. **Leave-one-out cross-validation accuracy**, where each of the 13 structures is predicted by a model that never saw it. Standardisation is fitted inside each fold, so no information leaks from the held-out structure.

On this dataset both models also reach 100% under leave-one-out validation, because the two classes are separable. The example therefore demonstrates a correct validation workflow; claims about generalisation would require a larger, field-measured dataset.

## Outputs

- `results/confusion_matrices.png`: leave-one-out confusion matrices for both models
- `results/accuracy_summary.csv`: training and leave-one-out accuracy

## Changes relative to the printed version

- Leave-one-out cross-validation added; the printed version evaluates on the training data only.
- The neural network is built with `fitcnet` (Statistics and Machine Learning Toolbox) instead of `trainNetwork` with `classificationLayer`, which MathWorks no longer recommends. The architecture is unchanged and the Deep Learning Toolbox is no longer required.
- Standardisation is handled inside each model (`'Standardize', true`), avoiding train–test leakage. Tree ensembles do not need scaling.
- Random seed fixed for reproducibility.
