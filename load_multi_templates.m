function [templates, template_names, template_groups] = load_multi_templates()

templates = {};
template_names = {};
template_groups = struct();
% Regardless of the original template's size, it ultimately becomes a 42 x 24 matrix.
target_size = [42, 24]; 
all_chars = ['0':'9', 'A':'Z'];

for i = 1:length(all_chars)
    c = all_chars(i);
    template_groups.(['char_' c]) = [];
end


% Normalize to 0-1, Binarize to black and white, Extract filenames and store them in the database.
multi_dir = 'templates_multi';
if exist(multi_dir, 'dir')
    files = dir(fullfile(multi_dir, '*.bmp'));
    
    for i = 1:length(files)
        filename = files(i).name;
        filepath = fullfile(multi_dir, filename);
        
        try
            img = imread(filepath);
            if size(img, 3) == 3
                img = rgb2gray(img);
            end
            img = double(img);
            if max(img(:)) > 1
                img = img / 255;
            end
            img = img > 0.5;
            img = imresize(double(img), target_size);
            img = img > 0.5;
            
            [~, name, ~] = fileparts(filename);
            parts = strsplit(name, '_');
            char_name = upper(parts{1});
            
            idx = length(templates) + 1;
            templates{idx} = double(img);
            template_names{idx} = char_name;
            
            field = ['char_' char_name];

            % If the character is already found in the general library, it will be skipped.
            if isfield(template_groups, field)
                template_groups.(field) = [template_groups.(field), idx];
            end
        catch
            continue;
        end
    end
end


% If not found, search the Ontario template library.
ontario_dir = 'templates_ontario';
if exist(ontario_dir, 'dir')
    files = dir(fullfile(ontario_dir, '*.bmp'));
    
    for i = 1:length(files)
        filename = files(i).name;
        [~, name, ~] = fileparts(filename);
        char_name = upper(name(1));
        field = ['char_' char_name];
        
        if isfield(template_groups, field) && ~isempty(template_groups.(field))
            continue;
        end
        
        filepath = fullfile(ontario_dir, filename);
        
        try
            img = imread(filepath);
            if size(img, 3) == 3
                img = rgb2gray(img);
            end
            img = double(img);
            if max(img(:)) > 1
                img = img / 255;
            end
            img = img > 0.5;
            img = imresize(double(img), target_size);
            img = img > 0.5;
            
            idx = length(templates) + 1;
            templates{idx} = double(img);
            template_names{idx} = char_name;
            
            if isfield(template_groups, field)
                template_groups.(field) = [template_groups.(field), idx];
            end
        catch
            continue;
        end
    end
end

mat_file = 'imgfildata.mat';
if exist(mat_file, 'file')
    try
        data = load(mat_file);
        if isfield(data, 'imgfile')
            imgfile = data.imgfile;
            num_old = size(imgfile, 2);
            
            for i = 1:num_old
                char_name = upper(imgfile{2, i});
                if length(char_name) ~= 1
                    continue;
                end
                
                field = ['char_' char_name];
                
                if isfield(template_groups, field) && ~isempty(template_groups.(field))
                    continue;
                end
                
                img = imgfile{1, i};
                if size(img, 3) == 3
                    img = rgb2gray(img);
                end
                img = double(img);
                if max(img(:)) > 1
                    img = img / 255;
                end
                img = img > 0.5;
                % White pixels dominate, triggering automatic color inversion to ensure all templates feature "black background with white text."
                if sum(img(:)) / numel(img) > 0.5
                    img = ~img;
                end
                img = imresize(double(img), target_size);
                img = img > 0.5;
                
                idx = length(templates) + 1;
                templates{idx} = double(img);
                template_names{idx} = char_name;
                
                if isfield(template_groups, field)
                    template_groups.(field) = [template_groups.(field), idx];
                end
            end
        end
    catch
    end
end

missing_chars = {};
for i = 1:length(all_chars)
    c = all_chars(i);
    field = ['char_' c];
    if ~isfield(template_groups, field) || isempty(template_groups.(field))
        missing_chars{end+1} = c;
    end
end

% If characters are missing from the file, they will be automatically completed.
if ~isempty(missing_chars)
    for i = 1:length(missing_chars)
        c = missing_chars{i};
        template = generate_standard_template(c, target_size);
        
        idx = length(templates) + 1;
        templates{idx} = template;
        template_names{idx} = c;
        
        field = ['char_' c];
        if isfield(template_groups, field)
            template_groups.(field) = [template_groups.(field), idx];
        end
    end
end

end

