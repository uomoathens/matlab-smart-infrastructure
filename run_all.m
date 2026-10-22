function run_all
root = fileparts(mfilename('fullpath'));
scripts = [
    "examples/01-digital-twin-bridge/digital_twin_bridge.m"
    "examples/02-shm-classification/shm_classification.m"
    "examples/03-iot-bridge-monitoring/iot_bridge_monitoring.m"
    "examples/04-athens-signal-ga/athens_signal_ga.m"
    "examples/05-wastewater-pareto/wastewater_pareto.m"
    "examples/06-construction-worker-safety/construction_worker_safety.m"
];
fontName = getenv('MSI_PLOT_FONT');
if ~isempty(fontName)
    set(groot, 'defaultAxesFontName', fontName, 'defaultTextFontName', fontName, ...
        'defaultLegendFontName', fontName, 'defaultColorbarFontName', fontName);
end
for i = 1:numel(scripts)
    runIsolated(fullfile(root, scripts(i)));
    close all;
end
end

function runIsolated(scriptPath)
fprintf('\n==== %s ====\n', scriptPath);
run(char(scriptPath));
end
