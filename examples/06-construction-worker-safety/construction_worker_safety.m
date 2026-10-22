rng(42);

exampleDir = fileparts(mfilename('fullpath'));
resultsDir = fullfile(exampleDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

opts.overlapThreshold = 0.3;
opts.persistenceSeconds = 0.5;
opts.saveVideo = false;
opts.resultsDir = resultsDir;

cases = struct('name', {}, 'videoPath', {}, 'detectorName', {}, 'zoneName', {}, 'zoneNormalized', {});

siteVideo = fullfile(exampleDir, 'data', 'site-construction-workers.mp4');
if isfile(siteVideo)
    cases(end + 1) = struct('name', "site", 'videoPath', siteVideo, 'detectorName', "inria", ...
        'zoneName', "Scaffold (working at height)", 'zoneNormalized', [0 0.25; 0.92 0.25; 0.92 1.00; 0 1.00]);
else
    fprintf('Site video not found at %s; running the demo case only.\n', siteVideo);
end

demoVideo = which('vippedtracking.mp4');
if isempty(demoVideo)
    error('The Computer Vision Toolbox sample video vippedtracking.mp4 was not found.');
end
cases(end + 1) = struct('name', "demo", 'videoPath', demoVideo, 'detectorName', "caltech", ...
    'zoneName', "Vehicle path", 'zoneNormalized', [0.30 1.00; 0.45 0.55; 0.55 0.55; 0.70 1.00]);

for c = 1:numel(cases)
    processVideo(cases(c), opts);
end

function processVideo(cfg, opts)
fprintf('\n---- Case: %s ----\nVideo: %s\n', cfg.name, cfg.videoPath);

if cfg.detectorName == "inria"
    detector = peopleDetectorACF();
else
    detector = peopleDetectorACF(char(cfg.detectorName));
end

reader = VideoReader(cfg.videoPath);
zone = cfg.zoneNormalized .* [reader.Width, reader.Height];
zoneName = char(cfg.zoneName);
prefix = cfg.name + "_";

if opts.saveVideo
    videoFig = figure('Name', 'Annotated video', 'Visible', 'off', ...
        'Position', [100 100 reader.Width reader.Height]);
    videoAx = axes(videoFig, 'Position', [0 0 1 1]);
    writer = VideoWriter(char(fullfile(opts.resultsDir, prefix + "annotated_video.avi")), 'Motion JPEG AVI');
    writer.FrameRate = reader.FrameRate;
    open(writer);
end

frameTimes = zeros(0, 1);
workerCounts = zeros(0, 1);
hazardCounts = zeros(0, 1);
bestHazard = -1;
bestWorkers = -1;
bestFrame = [];
bestBoxes = zeros(0, 4);
bestInZone = false(0, 1);
bestTime = 0;
k = 0;

while hasFrame(reader)
    t = reader.CurrentTime;
    frame = readFrame(reader);
    k = k + 1;

    [bboxes, scores] = detect(detector, frame, 'SelectStrongest', false);
    if ~isempty(bboxes)
        [bboxes, ~] = selectStrongestBbox(bboxes, scores, 'OverlapThreshold', opts.overlapThreshold);
    end
    inZone = footInZone(bboxes, zone);

    frameTimes(k, 1) = t;
    workerCounts(k, 1) = size(bboxes, 1);
    hazardCounts(k, 1) = nnz(inZone);

    if hazardCounts(k) > bestHazard || ...
            (hazardCounts(k) == bestHazard && workerCounts(k) > bestWorkers)
        bestHazard = hazardCounts(k);
        bestWorkers = workerCounts(k);
        bestFrame = frame;
        bestBoxes = bboxes;
        bestInZone = inZone;
        bestTime = t;
    end

    if opts.saveVideo
        drawAnnotations(videoAx, frame, bboxes, inZone, zone, zoneName);
        writeVideo(writer, getframe(videoAx));
    end
end

if opts.saveVideo
    close(writer);
    close(videoFig);
end

if k == 0
    error('The video %s contains no frames.', cfg.videoPath);
end

minFrames = max(1, round(opts.persistenceSeconds * reader.FrameRate));
hazardFlag = hazardCounts > 0;
edges = diff([0; double(hazardFlag); 0]);
starts = find(edges == 1);
stops = find(edges == -1) - 1;
keep = (stops - starts + 1) >= minFrames;
starts = starts(keep);
stops = stops(keep);
numEvents = numel(starts);

eventStart = frameTimes(starts);
eventEnd = frameTimes(stops) + 1 / reader.FrameRate;
peakInZone = zeros(numEvents, 1);
for e = 1:numEvents
    peakInZone(e) = max(hazardCounts(starts(e):stops(e)));
end

events = table((1:numEvents)', eventStart, eventEnd, eventEnd - eventStart, peakInZone, ...
    'VariableNames', {'Event', 'Start_s', 'End_s', 'Duration_s', 'PeakWorkersInZone'});

perFrame = table((1:k)', frameTimes, workerCounts, hazardCounts, ...
    'VariableNames', {'Frame', 'Time_s', 'WorkersDetected', 'WorkersInHazardZone'});

summary = table( ...
    ["Frames processed"; "Video duration (s)"; "Frame size (pixels)"; ...
     "Frames with at least one worker"; "Total worker detections"; ...
     "Frames with a worker in the hazard zone"; ...
     sprintf("Sustained hazard events (>= %.1f s)", opts.persistenceSeconds)], ...
    [string(k); sprintf("%.2f", k / reader.FrameRate); sprintf("%d x %d", reader.Width, reader.Height); ...
     string(nnz(workerCounts > 0)); string(sum(workerCounts)); ...
     string(nnz(hazardFlag)); string(numEvents)], ...
    'VariableNames', {'Metric', 'Value'});
disp(summary);
disp(events);

fig1 = figure('Name', 'Hazard frame', 'Position', [100 100 900 560]);
ax1 = axes(fig1);
drawAnnotations(ax1, bestFrame, bestBoxes, bestInZone, zone, zoneName);
title(ax1, sprintf('t = %.2f s: %d workers detected, %d in zone "%s"', ...
    bestTime, size(bestBoxes, 1), nnz(bestInZone), zoneName));
exportgraphics(fig1, fullfile(opts.resultsDir, prefix + "hazard_frame.png"), 'Resolution', 200);

fig2 = figure('Name', 'Hazard timeline', 'Position', [100 100 900 400]);
ax2 = axes(fig2);
hold(ax2, 'on');
if numEvents > 0
    xregion(ax2, eventStart, eventEnd, 'FaceColor', [0.85 0.1 0.1], 'FaceAlpha', 0.15);
end
hWorkers = stairs(ax2, frameTimes, workerCounts, 'Color', [0.2 0.4 0.8], 'LineWidth', 1.2);
hHazard = stairs(ax2, frameTimes, hazardCounts, 'Color', [0.85 0.1 0.1], 'LineWidth', 1.5);
hold(ax2, 'off');
xlabel(ax2, 'Time (s)');
ylabel(ax2, 'Count');
title(ax2, sprintf('Detections per frame, shaded: sustained hazard events (>= %.1f s)', ...
    opts.persistenceSeconds));
legend(ax2, [hWorkers, hHazard], {'Workers detected', 'In hazard zone'}, 'Location', 'northeast');
grid(ax2, 'on');
exportgraphics(fig2, fullfile(opts.resultsDir, prefix + "hazard_timeline.png"), 'Resolution', 200);

writetable(perFrame, fullfile(opts.resultsDir, prefix + "detections_per_frame.csv"));
writetable(events, fullfile(opts.resultsDir, prefix + "hazard_events.csv"));
writetable(summary, fullfile(opts.resultsDir, prefix + "summary.csv"));
end

function inZone = footInZone(bboxes, zone)
if isempty(bboxes)
    inZone = false(0, 1);
    return;
end
footX = bboxes(:, 1) + bboxes(:, 3) / 2;
footY = bboxes(:, 2) + bboxes(:, 4);
inZone = inpolygon(footX, footY, zone(:, 1), zone(:, 2));
end

function drawAnnotations(ax, frame, bboxes, inZone, zone, zoneName)
cla(ax);
image(ax, frame);
axis(ax, 'image');
axis(ax, 'off');
hold(ax, 'on');
patch(ax, zone(:, 1), zone(:, 2), [0.85 0.1 0.1], 'FaceAlpha', 0.15, ...
    'EdgeColor', [0.85 0.1 0.1], 'LineWidth', 1.5);
text(ax, min(zone(:, 1)) + 4, min(zone(:, 2)) + 4, zoneName, 'Color', 'w', ...
    'BackgroundColor', [0.85 0.1 0.1], 'FontSize', 9, 'VerticalAlignment', 'top', 'Margin', 1);
for i = 1:size(bboxes, 1)
    if inZone(i)
        boxColor = [0.85 0.1 0.1];
        label = 'Hazard';
        labelColor = 'w';
    else
        boxColor = [1 0.85 0];
        label = 'Worker';
        labelColor = 'k';
    end
    rectangle(ax, 'Position', bboxes(i, :), 'EdgeColor', boxColor, 'LineWidth', 2);
    text(ax, bboxes(i, 1), max(bboxes(i, 2) - 2, 1), label, 'Color', labelColor, ...
        'BackgroundColor', boxColor, 'FontSize', 8, 'VerticalAlignment', 'bottom', 'Margin', 1);
end
hold(ax, 'off');
drawnow;
end
