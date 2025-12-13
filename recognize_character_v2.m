function [result_char, confidence, details] = recognize_character_v2(char_img, templates, template_names, template_groups)

result_char = '?';
confidence = 0;
details = struct();

if isempty(char_img) || isempty(templates)
    return;
end

char_img = double(char_img);
if max(char_img(:)) > 1
    char_img = char_img / 255;
end

target_size = [42, 24];
if ~isequal(size(char_img), target_size)
    char_img = imresize(char_img, target_size);
end

Im = char_img > 0.5;
Im_inv = ~Im;

features = analyze_features(Im);
features_inv = analyze_features(Im_inv);

num_templates = length(templates);
scores = zeros(1, num_templates);
scores_inv = zeros(1, num_templates);

for k = 1:num_templates
    Template = templates{k};
    Template = double(Template);
    if max(Template(:)) > 1
        Template = Template / 255;
    end
    if ~isequal(size(Template), target_size)
        Template = imresize(Template, target_size);
    end
    Template = Template > 0.5;
    
    diff1 = 1 - sum(abs(double(Im(:)) - double(Template(:)))) / numel(Im);
    diff1_inv = 1 - sum(abs(double(Im_inv(:)) - double(Template(:)))) / numel(Im);
    
    corr1 = corr2(double(Im), double(Template));
    corr1_inv = corr2(double(Im_inv), double(Template));
    
    struct1 = compute_structural_similarity(Im, Template);
    struct1_inv = compute_structural_similarity(Im_inv, Template);
    
    scores(k) = diff1 * 0.5 + max(corr1, 0) * 0.3 + struct1 * 0.2;
    scores_inv(k) = diff1_inv * 0.5 + max(corr1_inv, 0) * 0.3 + struct1_inv * 0.2;
end

[best_score, ~] = max(scores);
[best_score_inv, ~] = max(scores_inv);

if best_score_inv > best_score
    use_scores = scores_inv;
    use_features = features_inv;
else
    use_scores = scores;
    use_features = features;
end

all_chars = ['0':'9', 'A':'Z'];
char_votes = zeros(1, length(all_chars));

for i = 1:length(all_chars)
    c = all_chars(i);
    char_indices = find(strcmp(template_names, c));
    
    if ~isempty(char_indices)
        char_scores = use_scores(char_indices);
        max_score = max(char_scores);
        avg_score = mean(char_scores);
        num_templates_for_char = length(char_indices);
        bonus = min(0.02 * (num_templates_for_char - 1), 0.05);
        char_votes(i) = max_score * 0.7 + avg_score * 0.3 + bonus;
    end
end

[sorted_votes, sort_idx] = sort(char_votes, 'descend');
top_candidates = all_chars(sort_idx(1:min(5, length(sort_idx))));
top_scores = sorted_votes(1:min(5, length(sorted_votes)));

result_char = top_candidates(1);
confidence = top_scores(1);

if length(top_scores) >= 2 && (top_scores(1) - top_scores(2)) < 0.05
    result_char = refine_with_features(top_candidates(1:min(3, end)), top_scores(1:min(3, end)), use_features);
end

details.top_candidates = top_candidates;
details.top_scores = top_scores;
details.features = use_features;

end

function f = analyze_features(Im)
    [rows, cols] = size(Im);
    
    f.fill = sum(Im(:)) / numel(Im);
    
    left_cols = max(1, round(cols * 0.35));
    right_start = max(1, round(cols * 0.65));
    top_rows = max(1, round(rows * 0.3));
    bottom_start = max(1, round(rows * 0.7));
    
    f.left = sum(sum(Im(:, 1:left_cols))) / (rows * left_cols);
    f.right = sum(sum(Im(:, right_start:end))) / (rows * (cols - right_start + 1));
    f.top = sum(sum(Im(1:top_rows, :))) / (top_rows * cols);
    f.bottom = sum(sum(Im(bottom_start:end, :))) / ((rows - bottom_start + 1) * cols);
    
    center_r1 = max(1, round(rows * 0.35));
    center_r2 = min(rows, round(rows * 0.65));
    center_c1 = max(1, round(cols * 0.3));
    center_c2 = min(cols, round(cols * 0.7));
    f.center = sum(sum(Im(center_r1:center_r2, center_c1:center_c2))) / ...
               ((center_r2 - center_r1 + 1) * (center_c2 - center_c1 + 1));
    
    mid_r1 = max(1, round(rows * 0.4));
    mid_r2 = min(rows, round(rows * 0.6));
    f.mid_h = sum(sum(Im(mid_r1:mid_r2, :))) / ((mid_r2 - mid_r1 + 1) * cols);
    
    col_proj = sum(Im, 1);
    f.width_ratio = sum(col_proj > rows * 0.15) / cols;
    
    [max_col_sum, ~] = max(col_proj);
    f.vert_concentration = max_col_sum / max(sum(Im(:)), 1);
    
    left_half = Im(:, 1:floor(cols/2));
    right_half = fliplr(Im(:, ceil(cols/2)+1:end));
    if size(left_half, 2) == size(right_half, 2)
        f.symmetry = 1 - sum(abs(left_half(:) - right_half(:))) / max(numel(left_half), 1);
    else
        f.symmetry = 0.5;
    end
    
    top_half = Im(1:floor(rows/2), :);
    bottom_half = flipud(Im(ceil(rows/2)+1:end, :));
    if size(top_half, 1) == size(bottom_half, 1)
        f.v_symmetry = 1 - sum(abs(top_half(:) - bottom_half(:))) / max(numel(top_half), 1);
    else
        f.v_symmetry = 0.5;
    end
    
    filled = imfill(Im, 'holes');
    hole_pixels = sum(filled(:) & ~Im(:));
    f.has_hole = hole_pixels > numel(Im) * 0.02;
    f.hole_ratio = hole_pixels / numel(Im);
    
    top_center_r = max(1, round(rows * 0.25));
    top_center_c1 = max(1, round(cols * 0.35));
    top_center_c2 = min(cols, round(cols * 0.65));
    top_center = Im(1:top_center_r, top_center_c1:top_center_c2);
    f.top_center_fill = sum(top_center(:)) / max(numel(top_center), 1);
    
    bottom_center_r = max(1, round(rows * 0.75));
    bottom_center = Im(bottom_center_r:end, top_center_c1:top_center_c2);
    f.bottom_center_fill = sum(bottom_center(:)) / max(numel(bottom_center), 1);
    
    f.edge_left = sum(Im(:, 1:max(1, round(cols*0.15)))) / (rows * max(1, round(cols*0.15)));
    f.edge_right = sum(Im(:, round(cols*0.85):end)) / (rows * (cols - round(cols*0.85) + 1));
end

function sim = compute_structural_similarity(Im1, Im2)
    [rows, cols] = size(Im1);
    block_r = floor(rows / 4);
    block_c = floor(cols / 4);
    
    if block_r < 1 || block_c < 1
        sim = corr2(double(Im1), double(Im2));
        return;
    end
    
    fills1 = zeros(4, 4);
    fills2 = zeros(4, 4);
    
    for i = 1:4
        for j = 1:4
            r_start = (i-1) * block_r + 1;
            r_end = min(i * block_r, rows);
            c_start = (j-1) * block_c + 1;
            c_end = min(j * block_c, cols);
            
            block1 = Im1(r_start:r_end, c_start:c_end);
            block2 = Im2(r_start:r_end, c_start:c_end);
            
            fills1(i, j) = mean(block1(:));
            fills2(i, j) = mean(block2(:));
        end
    end
    
    sim = 1 - mean(abs(fills1(:) - fills2(:)));
end

function result = refine_with_features(candidates, scores, f)
    result = candidates(1);
    c_set = candidates;
    
    if any(ismember({'0', 'O', 'D', 'Q'}, c_set))
        if f.left > f.right * 1.1 && f.edge_left > 0.3
            if any(strcmp(c_set, 'D'))
                result = 'D';
                return;
            end
        end
        if f.symmetry > 0.65 && f.has_hole && abs(f.left - f.right) < 0.1
            result = '0';
            return;
        end
        if f.has_hole && f.symmetry > 0.5 && f.symmetry < 0.7
            result = 'O';
            return;
        end
        if any(strcmp(c_set, 'Q')) && ~any(strcmp(c_set, '0'))
            result = '0';
            return;
        end
    end
    
    if any(ismember({'1', 'I', 'L', 'H'}, c_set))
        if f.width_ratio < 0.32 && f.fill < 0.22
            result = '1';
            return;
        elseif f.left > 0.25 && f.right > 0.2 && f.mid_h > 0.4
            result = 'H';
            return;
        elseif f.bottom > 0.35 && f.right > 0.25 && f.top < 0.2
            result = 'L';
            return;
        elseif f.width_ratio < 0.4 && f.fill < 0.28
            if f.top > 0.3 && f.bottom > 0.3
                result = 'I';
            else
                result = '1';
            end
            return;
        elseif f.width_ratio < 0.55 && f.top > 0.2 && f.bottom > 0.2
            result = 'I';
            return;
        end
    end
    
    if any(ismember({'2', 'Z'}, c_set))
        if f.has_hole || f.top > f.bottom * 0.5
            result = '2';
            return;
        else
            result = 'Z';
            return;
        end
    end
    
    if any(ismember({'5', 'S'}, c_set))
        if f.symmetry > 0.55 && f.v_symmetry > 0.45
            result = 'S';
            return;
        else
            result = '5';
            return;
        end
    end
    
    if any(ismember({'6', 'G', 'B', '0'}, c_set))
        if f.hole_ratio > 0.04 && f.mid_h > 0.35 && f.left > 0.3
            result = 'B';
            return;
        end
        if f.has_hole && f.bottom > f.top && f.top < 0.25
            result = '6';
            return;
        end
        if f.has_hole && f.right < 0.2 && f.left > 0.25
            result = 'G';
            return;
        end
        if f.has_hole && f.symmetry > 0.6 && f.left < 0.35
            result = '0';
            return;
        end
    end
    
    if any(ismember({'8', 'B'}, c_set))
        if f.symmetry > 0.6
            result = '8';
            return;
        else
            result = 'B';
            return;
        end
    end
    
    if all(ismember({'9', '6'}, c_set))
        if f.top > f.bottom
            result = '9';
            return;
        else
            result = '6';
            return;
        end
    end
    
    if any(ismember({'M', 'H', 'N'}, c_set))
        if f.top_center_fill < 0.25 && f.top > 0.25
            result = 'M';
            return;
        elseif f.mid_h > 0.45 && f.center > 0.35
            result = 'H';
            return;
        elseif f.fill > 0.3 && f.left > 0.25 && f.right > 0.25
            result = 'N';
            return;
        end
    end
    
    if any(ismember({'K', 'X'}, c_set))
        if f.left > 0.28
            result = 'K';
            return;
        elseif f.symmetry > 0.55
            result = 'X';
            return;
        end
    end
    
    if any(ismember({'V', 'Y'}, c_set))
        if f.bottom_center_fill > 0.4 && f.bottom > 0.25
            result = 'Y';
            return;
        elseif f.bottom_center_fill < 0.3
            result = 'V';
            return;
        else
            result = 'V';
            return;
        end
    end
    
    if any(ismember({'G', '6'}, c_set))
        if f.right < 0.12
            result = 'G';
            return;
        end
        if f.has_hole && f.bottom > f.top * 1.3
            result = '6';
            return;
        end
        if f.mid_h > 0.25 && f.right < 0.18
            result = 'G';
            return;
        end
        if f.right < 0.2
            result = 'G';
        else
            result = '6';
        end
        return;
    end
end
