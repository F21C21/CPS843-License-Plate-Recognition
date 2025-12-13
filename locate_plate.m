function [plate_region, plate_binary, bbox, success, plate_data] = locate_plate(img, varargin)

success = false;
plate_region = [];
plate_binary = [];
bbox = [];
plate_data = struct();

if isempty(img)
    return;
end

original_img = img;

% Image forced to 300x500
picture = imresize(img, [300 500]);
[rows, cols, ~] = size(picture);

if size(picture, 3) == 3
    gray = rgb2gray(picture);
    hsv = rgb2hsv(picture);
    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);
    red_bg = ((H < 0.08 | H > 0.92) & S > 0.3 & V > 0.2);
    white_chars = (S < 0.2) & (V > 0.65);
else
    gray = picture;
    red_bg = [];
    white_chars = [];
end

% Tried 6 methods to extract the foreground and stored the results in candidates
candidates = {};
scores = [];

threshold1 = graythresh(gray);
bw1 = imbinarize(gray, threshold1);
if sum(bw1(:)) > numel(bw1) * 0.5
    bw1_chars = ~bw1;
else
    bw1_chars = bw1;
end
bw1_chars = bwareaopen(bw1_chars, 30);
candidates{end+1} = bw1_chars;


scores(end+1) = evaluate_result(bw1_chars, rows);

threshold2 = threshold1 * 0.7;
bw2 = gray < (threshold2 * 255);
bw2 = bwareaopen(bw2, 30);
candidates{end+1} = bw2;
scores(end+1) = evaluate_result(bw2, rows);

threshold3 = min(0.95, threshold1 * 1.3);
bw3 = gray < (threshold3 * 255);
bw3 = bwareaopen(bw3, 30);
candidates{end+1} = bw3;
scores(end+1) = evaluate_result(bw3, rows);

bw4 = imbinarize(gray, 'adaptive', 'Sensitivity', 0.5);
if sum(bw4(:)) > numel(bw4) * 0.5
    bw4_chars = ~bw4;
else
    bw4_chars = bw4;
end
bw4_chars = bwareaopen(bw4_chars, 30);
candidates{end+1} = bw4_chars;
scores(end+1) = evaluate_result(bw4_chars, rows);

if ~isempty(red_bg) && sum(red_bg(:)) > 3000
    red_dilated = imdilate(red_bg, strel('disk', 15));
    white_in_red = white_chars & red_dilated;
    result = bwareaopen(white_in_red, 30);
    if sum(result(:)) > 200
        candidates{end+1} = result;
        scores(end+1) = evaluate_result(result, rows) * 1.3;
    end
end

binary_inv = ~imbinarize(gray, threshold1);
binary_inv = bwareaopen(binary_inv, 30);
picture1 = bwareaopen(binary_inv, 2500);
picture2_diff = binary_inv - picture1;
picture2_diff = logical(picture2_diff);
picture2_diff = bwareaopen(picture2_diff, 40);
candidates{end+1} = picture2_diff;
scores(end+1) = evaluate_result(picture2_diff, rows);


% Choose the highest score candidate
[~, best_idx] = max(scores);
picture2 = candidates{best_idx};
picture = picture2;

picture2_clean = picture2;
picture2_clean(1:round(rows*0.12), :) = 0;
picture2_clean(round(rows*0.88):end, :) = 0;

if sum(picture2_clean(:)) > 100
    picture2 = picture2_clean;
    picture = picture2;
end

plate_data.picture = logical(picture);
plate_data.picture2 = logical(picture2);
plate_data.resized_img = imresize(original_img, [300 500]);

[L, Ne] = bwlabel(picture2);
if Ne > 0
    stats = regionprops(L, 'BoundingBox');
    all_x1 = inf; all_y1 = inf; all_x2 = 0; all_y2 = 0;
    for i = 1:Ne
        bb = stats(i).BoundingBox;
        all_x1 = min(all_x1, bb(1));
        all_y1 = min(all_y1, bb(2));
        all_x2 = max(all_x2, bb(1) + bb(3));
        all_y2 = max(all_y2, bb(2) + bb(4));
    end
    margin = 5;
    bbox = [max(1, all_x1-margin), max(1, all_y1-margin), ...
            min(500, all_x2+margin) - max(1, all_x1-margin), ...
            min(300, all_y2+margin) - max(1, all_y1-margin)];
end

plate_region = plate_data.resized_img;
plate_binary = struct();
plate_binary.picture = logical(picture);
plate_binary.picture2 = logical(picture2);
plate_binary.for_extract = logical(picture);
plate_binary.for_display = logical(picture2);
success = true;

end


% Heuristic Algorithm
function score = evaluate_result(bw, rows)
    bw_clean = bw;
    bw_clean(1:round(rows*0.12), :) = 0;
    bw_clean(round(rows*0.88):end, :) = 0;
    
    [L, Ne] = bwlabel(bw_clean);
    
    if Ne < 2 || Ne > 25
        score = Ne * 0.1;
        return;
    end
    
    stats = regionprops(L, 'BoundingBox', 'Area', 'Centroid');
    heights = zeros(Ne, 1);
    cy_list = zeros(Ne, 1);
    for i = 1:Ne
        heights(i) = stats(i).BoundingBox(4);
        cy_list(i) = stats(i).Centroid(2);
    end
    
    middle_mask = cy_list > rows * 0.2 & cy_list < rows * 0.8;
    
    if sum(middle_mask) < 2
        score = sum(middle_mask) * 0.5;
        return;
    end
    
    middle_heights = heights(middle_mask);
    max_h = max(middle_heights);
    main_mask = middle_heights >= max_h * 0.4;
    main_count = sum(main_mask);
    
    score = main_count * mean(middle_heights(main_mask));
    
    if main_count >= 4 && main_count <= 9
        score = score * 2;
    elseif main_count >= 3 && main_count <= 10
        score = score * 1.5;
    end
end
