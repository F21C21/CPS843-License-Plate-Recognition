function result = smart_postprocess(recognized, char_images)

result = recognized;

if isempty(recognized)
    return;
end

n = length(recognized);
corrected = '';

for i = 1:n
    c = recognized(i);
    
    if i <= length(char_images) && ~isempty(char_images{i})
        char_img = char_images{i};
        f = analyze_char_features(char_img);
        c = correct_by_features(c, f);
    end
    
    corrected = [corrected, c];
end

result = corrected;
result = apply_global_rules(result);

end

function f = analyze_char_features(char_img)
    char_img = double(char_img);
    if max(char_img(:)) > 1
        char_img = char_img / 255;
    end
    Im = char_img > 0.5;
    
    [rows, cols] = size(Im);
    
    f.fill = sum(Im(:)) / numel(Im);
    
    left_cols = max(1, round(cols * 0.35));
    right_start = max(1, round(cols * 0.65));
    
    f.left = sum(sum(Im(:, 1:left_cols))) / (rows * left_cols);
    f.right = sum(sum(Im(:, right_start:end))) / (rows * (cols - right_start + 1));
    
    top_rows = max(1, round(rows * 0.3));
    bottom_start = max(1, round(rows * 0.7));
    f.top = sum(sum(Im(1:top_rows, :))) / (top_rows * cols);
    f.bottom = sum(sum(Im(bottom_start:end, :))) / ((rows - bottom_start + 1) * cols);
    
    col_proj = sum(Im, 1);
    f.width_ratio = sum(col_proj > rows * 0.15) / cols;
    
    left_half = Im(:, 1:floor(cols/2));
    right_half = fliplr(Im(:, ceil(cols/2)+1:end));
    if size(left_half, 2) == size(right_half, 2)
        f.symmetry = 1 - sum(abs(left_half(:) - right_half(:))) / max(numel(left_half), 1);
    else
        f.symmetry = 0.5;
    end
    
    filled = imfill(Im, 'holes');
    f.has_hole = sum(filled(:) & ~Im(:)) > numel(Im) * 0.02;
    
    mid_r1 = max(1, round(rows * 0.4));
    mid_r2 = min(rows, round(rows * 0.6));
    f.mid_h = sum(sum(Im(mid_r1:mid_r2, :))) / ((mid_r2 - mid_r1 + 1) * cols);
end

function c = correct_by_features(c, f)
    if f.width_ratio < 0.32 && f.fill < 0.22
        c = '1';
        return;
    end
    
    if ismember(c, {'H', 'I', 'U'}) && f.width_ratio < 0.38 && f.fill < 0.26
        c = '1';
        return;
    end
    
    if c == 'D'
        if f.left > f.right * 1.05
            return;
        end
    end
    
    if c == 'V'
        return;
    end
    
    if c == 'G'
        if f.right < 0.2
            return;
        end
    end
    
    if c == 'O' && f.symmetry < 0.7
        return;
    end
    
    if c == 'Q' && f.has_hole
        c = '0';
        return;
    end
    
    if c == 'Z' && f.symmetry < 0.5
        c = '2';
        return;
    end
    
    if c == 'S' && f.symmetry < 0.4 && f.bottom > f.top * 1.2
        c = '5';
        return;
    end
    
    if c == 'B' && f.symmetry > 0.72
        c = '8';
        return;
    end
    
    if c == '1' && f.mid_h > 0.5 && f.width_ratio > 0.55 && f.left > 0.25 && f.right > 0.2
        c = 'H';
        return;
    end
end

function result = apply_global_rules(recognized)
    result = recognized;
    result = regexprep(result, '\?', '');
end
