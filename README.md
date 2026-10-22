# MATLAB for Smart Infrastructure

[![DOI](https://zenodo.org/badge/1429348142.svg)](https://doi.org/10.5281/zenodo.23555622) [![Run examples](https://github.com/uomoathens/matlab-smart-infrastructure/actions/workflows/run-examples.yml/badge.svg)](https://github.com/uomoathens/matlab-smart-infrastructure/actions/workflows/run-examples.yml)

Companion code for selected case studies from Chapter 15 of

> Sargiotis, D. (2025). *MATLAB for Civil Engineers: From Basics to Advanced Applications*. Springer Nature Switzerland. https://doi.org/10.1007/978-3-031-84673-1

The five examples cover data-driven methods for civil infrastructure: a machine-learning digital twin, structural health classification, IoT sensor monitoring, metaheuristic traffic-signal optimisation for Athens, and multi-objective design of a wastewater treatment plant. Each example is a self-contained, reproducible script that writes its figures and tables to a local `results/` folder.

## Examples

| # | Example | Book section | Methods | Toolboxes |
|---|---------|--------------|---------|-----------|
| 01 | [Digital twin for bridge stress monitoring](examples/01-digital-twin-bridge) | 15.6.2 | Bagged regression trees, hold-out validation, streaming prediction, threshold alerts | Statistics and Machine Learning |
| 02 | [Structural health classification](examples/02-shm-classification) | 15.6.1 | Bagged decision trees, shallow neural network, leave-one-out cross-validation | Statistics and Machine Learning |
| 03 | [IoT structural monitoring of a bridge](examples/03-iot-bridge-monitoring) | 15.6.3 | Multi-sensor streams, threshold and persistence-based alarms | None |
| 04 | [Traffic signal optimisation in Athens](examples/04-athens-signal-ga) | 15.6.3 | Genetic algorithm with hybrid local search, closed-form verification | Optimization, Global Optimization |
| 05 | [Wastewater treatment plant design](examples/05-wastewater-pareto) | 15.4.6 | NSGA-II style multi-objective GA, Pareto front, compromise selection | Optimization, Global Optimization |

## Requirements

MATLAB R2023b or later. Toolboxes per example are listed above.

## Running

Run all examples from the repository root:

```matlab
run_all
```

or open any script in `examples/` and run it on its own. Every script fixes the random seed with `rng(42)`, so results are reproducible on a given MATLAB release. All examples are also run automatically in GitHub Actions on MATLAB with the required toolboxes, and the `results/` folders in this repository are regenerated whenever the code changes. Examples 01 and 03 also contain a `liveMode` flag; set it to `true` for an animated, real-time view of the sensor stream.

## Relation to the printed text

The scripts follow the models and parameters of the book. They have been revised for public release: fixed random seeds, proper validation of the learning models, data read from files instead of hard-coded placeholders, independent verification of optimisation results, and figures exported automatically. Each example's README lists the specific changes.

## Citation

If you use this code, please cite the book (see [`CITATION.cff`](CITATION.cff)).

## License

Released under the MIT License. See [`LICENSE`](LICENSE).
