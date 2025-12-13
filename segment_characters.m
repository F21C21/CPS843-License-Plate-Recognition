function [char_images, num_chars, char_boxes, best_binary] = segment_characters(plate_binary, plate_region)

char_images = {};
num_chars = 0;
char_boxes = [];
best_binary = [];

if isempty(plate_binary)
    return;
end

if isstruct(plate_binary)
    if isfield(plate_binary, 'picture2')
        picture2 = logical(plate_binary.picture2);
    elseif isfield(plate_binary, 'for_extract')
        picture2 = logical(plate_binary.for_extract);
    else
        return;
    end
    if isfield(plate_binary, 'picture')
        picture = logical(plate_binary.picture);
    else
        picture = picture2;
    end
else
    picture = double(plate_binary) > 0.5;
    picture2 = picture;
end

[rows, cols] = size(picture2);

if nargin >= 2 && ~isempty(plate_region)
    if size(plate_region, 3) == 3
        gray = rgb2gray(plate_region);
    else
        gray = plate_region;
    end
    gray = imresize(gray, [rows, cols]);
    
    candidates = {};
    
    thresh1 = graythresh(gray);
    bw1 = imbinarize(gray, thresh1);
    candidates{end+1} = bw1;
    candidates{end+1} = ~bw1;
    
    thresh2 = thresh1 * 0.6;
    bw2 = gray < (thresh2 * 255);
    candidates{end+1} = bw2;
    candidates{end+1} = ~bw2;
    
    thresh3 = min(0.9, thresh1 * 1.4);
    bw3 = gray < (thresh3 * 255);
    candidates{end+1} = bw3;
    candidates{end+1} = ~bw3;
    
    bw4 = imbinarize(gray, 'adaptive', 'Sensitivity', 0.4);
    candidates{end+1} = bw4;
    candidates{end+1} = ~bw4;
    
    bw5 = imbinarize(gray, 'adaptive', 'Sensitivity', 0.6);
    candidates{end+1} = bw5;
    candidates{end+1} = ~bw5;
    
    candidates{end+1} = picture2;
    candidates{end+1} = ~picture2;
    
    best_result = [];
    best_score = -1;
    best_bw = [];
    
    for i = 1:length(candidates)
        bw = candidates{i};
        bw = bwareaopen(bw, 20);
        result = try_segment(bw, bw, rows, cols);
        score = result.num_chars;
        if score >= 3 && score <= 9
            score = score * 10;
        elseif score >= 2 && score <= 10
            score = score * 5;
        end
        if score > best_score
            best_score = score;
            best_result = result;
            best_bw = bw;
        end
    end
    
    if best_score > 0 && ~isempty(best_result)
        char_images = best_result.char_images;
        num_chars = best_result.num_chars;
        char_boxes = best_result.char_boxes;
        best_binary = best_bw;
        return;
    end
end

result1 = try_segment(picture2, picture, rows, cols);
result2 = try_segment(~picture2, ~picture, rows, cols);

if result1.num_chars >= result2.num_chars && result1.num_chars >= 2
    char_images = result1.char_images;
    num_chars = result1.num_chars;
    char_boxes = result1.char_boxes;
    best_binary = picture2;
elseif result2.num_chars >= 2
    char_images = result2.char_images;
    num_chars = result2.num_chars;
    char_boxes = result2.char_boxes;
    best_binary = ~picture2;
else
    if result1.num_chars >= result2.num_chars
        char_images = result1.char_images;
        num_chars = result1.num_chars;
        char_boxes = result1.char_boxes;
        best_binary = picture2;
    else
        char_images = result2.char_images;
        num_chars = result2.num_chars;
        char_boxes = result2.char_boxes;
        best_binary = ~picture2;
    end
end

end

function result = try_segment(picture2, picture, rows, cols)

result.char_images = {};
result.num_chars = 0;
result.char_boxes = [];

picture2_clean = picture2;
picture2_clean(1:round(rows*0.12), :) = 0;
picture2_clean(round(rows*0.88):end, :) = 0;

left_margin = max(1, round(cols * 0.05));
left_region = picture2_clean(:, 1:left_margin);
if sum(left_region(:)) / numel(left_region) > 0.3
    picture2_clean(:, 1:left_margin) = 0;
end

right_margin = max(1, round(cols * 0.05));
right_region = picture2_clean(:, cols-right_margin+1:end);
if sum(right_region(:)) / numel(right_region) > 0.3
    picture2_clean(:, cols-right_margin+1:end) = 0;
end

[L, Ne] = bwlabel(picture2_clean);
if Ne == 0
    return;
end

stats = regionprops(L, 'BoundingBox', 'Area', 'Centroid', 'Solidity');

regions = [];
for n = 1:Ne
    bb = stats(n).BoundingBox;
    x = bb(1); y = bb(2); w = bb(3); h = bb(4);
    area = stats(n).Area;
    cx = stats(n).Centroid(1);
    cy = stats(n).Centroid(2);
    aspect = h / max(w, 1);
    solidity = stats(n).Solidity;
    regions = [regions; n, x, y, w, h, area, cx, cy, aspect, solidity];
end

if isempty(regions)
    return;
end

heights = regions(:, 5);
widths = regions(:, 4);
areas = regions(:, 6);
cy_list = regions(:, 8);
max_height = max(heights);

keep = true(size(regions, 1), 1);

for i = 1:size(regions, 1)
    h = heights(i);
    w = widths(i);
    area = areas(i);
    cy = cy_list(i);
    
    if h < max_height * 0.3 || area < 40
        keep(i) = false;
        continue;
    end
    if w > h * 2 && w > cols * 0.15
        keep(i) = false;
        continue;
    end
    if cy < rows * 0.15 || cy > rows * 0.85
        keep(i) = false;
        continue;
    end
end

main_regions = regions(keep, :);
if isempty(main_regions)
    return;
end

main_cy = main_regions(:, 8);
main_heights = main_regions(:, 5);

[sorted_cy, sort_idx] = sort(main_cy);
sorted_regions = main_regions(sort_idx, :);
sorted_heights = main_heights(sort_idx);

lines = {};
current_line = [1];
current_y_mean = sorted_cy(1);

for i = 2:length(sorted_cy)
    ref_height = max(sorted_heights(current_line));
    if abs(sorted_cy(i) - current_y_mean) < ref_height * 0.5
        current_line = [current_line, i];
        current_y_mean = mean(sorted_cy(current_line));
    else
        lines{end+1} = current_line;
        current_line = [i];
        current_y_mean = sorted_cy(i);
    end
end
lines{end+1} = current_line;

best_line = [];
best_score = -inf;

for i = 1:length(lines)
    idx = lines{i};
    if isempty(idx)
        continue;
    end
    line_heights = sorted_heights(idx);
    avg_height = mean(line_heights);
    num_in_line = length(idx);
    score = avg_height * sqrt(num_in_line);
    if score > best_score
        best_score = score;
        best_line = idx;
    end
end

if isempty(best_line)
    best_line = 1:size(sorted_regions, 1);
end

line_regions = sorted_regions(best_line, :);

if size(line_regions, 1) >= 2
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    line_solidities = line_regions(:, 10);
    line_areas = line_regions(:, 6);
    
    median_w = median(line_widths);
    median_h = median(line_heights);
    median_area = median(line_areas);
    num_reg = size(line_regions, 1);
    
    keep2 = true(num_reg, 1);
    
    for i = 1:num_reg
        w = line_widths(i);
        h = line_heights(i);
        solidity = line_solidities(i);
        area = line_areas(i);
        
        if w > median_w * 2.5 && w > h * 1.3
            keep2(i) = false;
            continue;
        end
        if h < median_h * 0.5
            keep2(i) = false;
            continue;
        end
        if solidity < 0.4
            keep2(i) = false;
            continue;
        end
        if num_reg >= 5 && i > 2 && i < num_reg - 1
            if solidity < 0.55 && area < median_area * 0.8
                keep2(i) = false;
                continue;
            end
            if w > median_w * 1.8 && solidity < 0.6
                keep2(i) = false;
                continue;
            end
        end
    end
    
    filtered_line = line_regions(keep2, :);
    if ~isempty(filtered_line) && size(filtered_line, 1) >= 2
        line_regions = filtered_line;
    end
end

if isempty(line_regions)
    return;
end

[~, x_order] = sort(line_regions(:, 2));
line_regions = line_regions(x_order, :);

if size(line_regions, 1) >= 3
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    line_x = line_regions(:, 2);
    line_solidities = line_regions(:, 10);
    line_areas = line_regions(:, 6);
    
    median_w = median(line_widths);
    median_area = median(line_areas);
    total_width = max(line_x + line_widths) - min(line_x);
    
    keep3 = true(size(line_regions, 1), 1);
    
    for i = 1:size(line_regions, 1)
        w = line_widths(i);
        h = line_heights(i);
        x = line_x(i);
        solidity = line_solidities(i);
        area = line_areas(i);
        aspect = h / max(w, 1);
        
        if w < median_w * 0.3 && aspect > 3
            keep3(i) = false;
            continue;
        end
        if i == 1 && w < median_w * 0.5 && aspect > 2.5
            keep3(i) = false;
            continue;
        end
        if i == size(line_regions, 1) && w < median_w * 0.5 && aspect > 2.5
            keep3(i) = false;
            continue;
        end
        if aspect > 6 || aspect < 0.35
            keep3(i) = false;
            continue;
        end
        if i <= 2 && x < total_width * 0.2
            if solidity < 0.5
                keep3(i) = false;
                continue;
            end
            if w > median_w * 1.4 && solidity < 0.65
                keep3(i) = false;
                continue;
            end
            if area > median_area * 1.3 && solidity < 0.6
                keep3(i) = false;
                continue;
            end
        end
        if i >= size(line_regions, 1) - 1 && x > total_width * 0.85
            if solidity < 0.5
                keep3(i) = false;
                continue;
            end
            if w > median_w * 1.4 && solidity < 0.65
                keep3(i) = false;
                continue;
            end
        end
        if area < median_area * 0.25
            keep3(i) = false;
            continue;
        end
    end
    
    filtered_regions = line_regions(keep3, :);
    if size(filtered_regions, 1) >= 2
        line_regions = filtered_regions;
    end
end

if size(line_regions, 1) > 7
    num_reg = size(line_regions, 1);
    char_scores = zeros(num_reg, 1);
    
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    line_areas = line_regions(:, 6);
    line_solidities = line_regions(:, 10);
    line_x = line_regions(:, 2);
    
    median_w = median(line_widths);
    median_h = median(line_heights);
    median_area = median(line_areas);
    total_x_range = max(line_x + line_widths) - min(line_x);
    
    for i = 1:num_reg
        w = line_widths(i);
        h = line_heights(i);
        area = line_areas(i);
        solidity = line_solidities(i);
        x = line_x(i);
        
        score = 50;
        
        w_ratio = w / max(median_w, 1);
        if w_ratio > 0.6 && w_ratio < 1.8
            score = score + 25;
        elseif w_ratio > 0.4 && w_ratio < 2.2
            score = score + 10;
        end
        
        h_ratio = h / max(median_h, 1);
        if h_ratio > 0.7 && h_ratio < 1.4
            score = score + 25;
        elseif h_ratio > 0.5 && h_ratio < 1.6
            score = score + 10;
        end
        
        if solidity > 0.55
            score = score + 15;
        elseif solidity > 0.4
            score = score + 5;
        end
        
        if i == 1 || i == num_reg
            score = score - 25;
            if w < median_w * 0.6
                score = score - 20;
            end
        end
        
        if i == 2 || i == num_reg - 1
            if w < median_w * 0.5
                score = score - 15;
            end
        end
        
        if w < median_w * 0.35
            score = score - 40;
        elseif w < median_w * 0.5
            score = score - 20;
        end
        
        if area > median_area * 2.5
            score = score - 25;
        elseif area < median_area * 0.25
            score = score - 25;
        end
        
        if x < total_x_range * 0.05
            score = score - 15;
        end
        if x > total_x_range * 0.9
            score = score - 15;
        end
        
        char_scores(i) = score;
    end
    
    [~, sorted_idx] = sort(char_scores, 'descend');
    keep_count = min(7, num_reg);
    keep_idx = sort(sorted_idx(1:keep_count));
    line_regions = line_regions(keep_idx, :);
end

if size(line_regions, 1) >= 3
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    line_areas = line_regions(:, 6);
    median_w = median(line_widths);
    median_area = median(line_areas);
    
    first_w = line_widths(1);
    last_w = line_widths(end);
    first_aspect = line_heights(1) / max(first_w, 1);
    last_aspect = line_heights(end) / max(last_w, 1);
    first_area = line_areas(1);
    last_area = line_areas(end);
    
    remove_first = false;
    remove_last = false;
    
    if first_w < median_w * 0.5 && first_aspect > 2.5
        remove_first = true;
    end
    if first_area < median_area * 0.35
        remove_first = true;
    end
    if last_w < median_w * 0.5 && last_aspect > 2.5
        remove_last = true;
    end
    if last_area < median_area * 0.35
        remove_last = true;
    end
    
    if remove_first && remove_last
        line_regions = line_regions(2:end-1, :);
    elseif remove_first
        line_regions = line_regions(2:end, :);
    elseif remove_last
        line_regions = line_regions(1:end-1, :);
    end
end

if size(line_regions, 1) == 7
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    line_areas = line_regions(:, 6);
    line_solidities = line_regions(:, 10);
    
    median_w = median(line_widths);
    median_area = median(line_areas);
    
    first_score = 0;
    last_score = 0;
    
    w = line_widths(1);
    h = line_heights(1);
    area = line_areas(1);
    solidity = line_solidities(1);
    aspect = h / max(w, 1);
    
    if w < median_w * 0.4
        first_score = first_score + 40;
    elseif w < median_w * 0.55
        first_score = first_score + 20;
    end
    if area < median_area * 0.35
        first_score = first_score + 35;
    elseif area < median_area * 0.5
        first_score = first_score + 15;
    end
    if aspect > 4
        first_score = first_score + 25;
    elseif aspect > 3
        first_score = first_score + 10;
    end
    if solidity < 0.4
        first_score = first_score + 20;
    end
    
    w = line_widths(7);
    h = line_heights(7);
    area = line_areas(7);
    solidity = line_solidities(7);
    aspect = h / max(w, 1);
    
    if w < median_w * 0.4
        last_score = last_score + 40;
    elseif w < median_w * 0.55
        last_score = last_score + 20;
    end
    if area < median_area * 0.35
        last_score = last_score + 35;
    elseif area < median_area * 0.5
        last_score = last_score + 15;
    end
    if aspect > 4
        last_score = last_score + 25;
    elseif aspect > 3
        last_score = last_score + 10;
    end
    if solidity < 0.4
        last_score = last_score + 20;
    end
    
    threshold = 35;
    if first_score >= threshold && first_score > last_score + 10
        line_regions = line_regions(2:end, :);
    elseif last_score >= threshold && last_score > first_score + 10
        line_regions = line_regions(1:end-1, :);
    elseif first_score >= threshold + 15 && first_score >= last_score
        line_regions = line_regions(2:end, :);
    elseif last_score >= threshold + 15
        line_regions = line_regions(1:end-1, :);
    end
end

if size(line_regions, 1) == 7
    line_widths = line_regions(:, 4);
    line_heights = line_regions(:, 5);
    median_w = median(line_widths);
    
    first_w = line_widths(1);
    first_h = line_heights(1);
    first_aspect = first_h / max(first_w, 1);
    
    last_w = line_widths(7);
    last_h = line_heights(7);
    last_aspect = last_h / max(last_w, 1);
    
    remove_first = false;
    remove_last = false;
    
    if first_w < median_w * 0.45 && first_aspect > 3.5
        remove_first = true;
    end
    if last_w < median_w * 0.45 && last_aspect > 3.5
        remove_last = true;
    end
    
    if remove_first && remove_last
        if first_w < last_w
            line_regions = line_regions(2:end, :);
        else
            line_regions = line_regions(1:end-1, :);
        end
    elseif remove_first
        line_regions = line_regions(2:end, :);
    elseif remove_last
        line_regions = line_regions(1:end-1, :);
    end
end

num_chars = size(line_regions, 1);
char_images = cell(1, num_chars);
char_boxes = zeros(num_chars, 4);

for i = 1:num_chars
    n = line_regions(i, 1);
    bb = stats(n).BoundingBox;
    char_boxes(i, :) = bb;
    
    [r, c] = find(L == n);
    if isempty(r)
        continue;
    end
    
    n1 = picture2_clean(min(r):max(r), min(c):max(c));
    n1 = imresize(double(n1), [42, 24]);
    n1 = n1 > 0.5;
    char_images{i} = double(n1);
end

result.char_images = char_images;
result.num_chars = num_chars;
result.char_boxes = char_boxes;

end
