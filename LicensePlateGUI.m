function LicensePlateGUI()
    
    clear functions;
    clc;
    close all;
    
    hFig = figure('Name', 'License Plate Recognition System ', ...
                  'NumberTitle', 'off', ...
                  'Position', [100, 50, 1200, 700], ...
                  'MenuBar', 'none', ...
                  'ToolBar', 'figure', ...
                  'Resize', 'off', ...
                  'Color', [0.94, 0.94, 0.94]);
    
    handles = struct();
    handles.img = [];
    handles.templates = {};
    handles.template_names = {};
    handles.template_groups = struct();
    
    hWait = waitbar(0, 'Initializing system templates...');
    try
        [handles.templates, handles.template_names, handles.template_groups] = load_multi_templates();
        waitbar(1, hWait, 'Initialization complete');
    catch
    end
    pause(0.5);
    close(hWait);
    
    uicontrol(hFig, 'Style', 'text', 'String', 'MATLAB License Plate Recognition System', ...
              'Position', [400, 660, 400, 30], ...
              'FontSize', 18, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94, 0.94, 0.94]);
    
    panel_ctrl = uipanel(hFig, 'Title', 'Control Panel', ...
                         'Position', [0.01, 0.35, 0.12, 0.55], ...
                         'FontSize', 11);
                     
    uicontrol(panel_ctrl, 'Style', 'pushbutton', 'String', '1. Load Image', ...
              'Position', [10, 260, 110, 40], 'FontSize', 10, ...
              'Callback', @cb_load);
    handles.btn_run = uicontrol(panel_ctrl, 'Style', 'pushbutton', 'String', '2. Start Recognition', ...
              'Position', [10, 190, 110, 40], 'FontSize', 10, ...
              'Enable', 'off', ...
              'Callback', @cb_run);
          
    uicontrol(panel_ctrl, 'Style', 'pushbutton', 'String', '3. Clear All', ...
              'Position', [10, 120, 110, 40], 'FontSize', 10, ...
              'Callback', @cb_clear);
          
    uicontrol(panel_ctrl, 'Style', 'pushbutton', 'String', 'Exit System', ...
              'Position', [10, 30, 110, 35], 'FontSize', 10, ...
              'Callback', @(~,~) close(hFig));
    
    panel_res = uipanel(hFig, 'Title', 'Recognition Result', ...
                        'Position', [0.01, 0.15, 0.12, 0.18], ...
                        'FontSize', 11);
    handles.edit_result = uicontrol(panel_res, 'Style', 'edit', 'String', '', ...
              'Position', [5, 30, 120, 40], ...
              'FontSize', 14, 'FontWeight', 'bold', ...
              'BackgroundColor', [1 1 1], 'Enable', 'inactive', ...
              'HorizontalAlignment', 'center');
    
    handles.ax_src = axes('Parent', hFig, 'Position', [0.15, 0.60, 0.25, 0.30]);
    title('1. Original Image'); axis off; box on;
    
    handles.ax_hist = axes('Parent', hFig, 'Position', [0.43, 0.60, 0.25, 0.30]);
    title('2. Grayscale Histogram'); grid on; box on; 
    
    handles.ax_canny = axes('Parent', hFig, 'Position', [0.71, 0.60, 0.25, 0.30]);
    title('3. Canny Edge Detection'); axis off; box on;
    
    handles.ax_binary = axes('Parent', hFig, 'Position', [0.15, 0.22, 0.25, 0.30]);
    title('4. Global Binarization'); axis off; box on;
    
    handles.ax_plate = axes('Parent', hFig, 'Position', [0.43, 0.25, 0.25, 0.24]);
    title('5. Detected Plate Region'); axis off; box on;
    
    for i = 1:7
        x_pos = 0.71 + (i-1) * 0.038;
        handles.ax_chars{i} = axes('Parent', hFig, 'Position', [x_pos, 0.28, 0.035, 0.15]);
        axis off;
    end
    
    annotation(hFig, 'textbox', [0.71, 0.44, 0.25, 0.05], 'String', '6. Character Segmentation', ...
               'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    
    guidata(hFig, handles);

    function cb_load(~, ~)
        h = guidata(hFig);
        [fname, pname] = uigetfile({'*.jpg;*.png;*.bmp;*.jpeg'}, 'Select Test Image');
        if fname == 0, return; end
        
        filepath = fullfile(pname, fname);
        h.img = imread(filepath);
        
        axes(h.ax_src);
        imshow(h.img);
        title('1. Original Image');
        
        if size(h.img, 3) == 3
            gray = rgb2gray(h.img);
        else
            gray = h.img;
        end
        axes(h.ax_hist);
        imhist(gray);
        title('2. Grayscale Histogram'); grid on;
        
        set(h.btn_run, 'Enable', 'on');
        set(h.edit_result, 'String', '');
        
        guidata(hFig, h);
    end

    function cb_run(~, ~)
        h = guidata(hFig);
        if isempty(h.img), return; end
        set(h.edit_result, 'String', '...'); drawnow;
        
        try
            if size(h.img, 3) == 3
                gray = rgb2gray(h.img);
            else
                gray = h.img;
            end
            
            bw_canny = edge(gray, 'canny');
            axes(h.ax_canny);
            imshow(bw_canny);
            title('3. Canny Edge Detection');
            drawnow;
            
            [~, binary_img, ~, edge_img, ~] = preprocess_image(h.img);
            
            axes(h.ax_binary);
            imshow(binary_img);
            title('4. Global Binarization');
            drawnow;
            
            [plate_region, plate_binary, ~, success] = locate_plate(h.img, edge_img);
            
            if ~success || isempty(plate_region)
                msgbox('Localization failed. Please try another image.', 'Info');
                set(h.edit_result, 'String', 'Failed');
                return;
            end
            
            axes(h.ax_plate);
            imshow(plate_region);
            title('5. Detected Plate Region');
            
            [char_images, num_chars, ~, ~] = segment_characters(plate_binary, plate_region);
            
            for k = 1:7
                axes(h.ax_chars{k}); cla;
                if k <= num_chars && ~isempty(char_images{k})
                    imshow(char_images{k});
                end
                axis off;
            end
            
            raw_result = '';
            for k = 1:num_chars
                if ~isempty(char_images{k})
                    [c, ~, ~] = recognize_character_v2(char_images{k}, h.templates, h.template_names, h.template_groups);
                    raw_result = [raw_result, c];
                end
            end
            
            final_result = smart_postprocess(raw_result, char_images);
            set(h.edit_result, 'String', final_result);
            
        catch ME
            errordlg(ME.message, 'Error');
        end
    end

    function cb_clear(~, ~)
        h = guidata(hFig);
        h.img = [];
        set(h.btn_run, 'Enable', 'off');
        set(h.edit_result, 'String', '');
        
        axes(h.ax_src); cla; title('1. Original Image'); axis off;
        axes(h.ax_hist); cla; title('2. Grayscale Histogram');
        axes(h.ax_canny); cla; title('3. Canny Edge Detection'); axis off;
        axes(h.ax_binary); cla; title('4. Global Binarization'); axis off;
        axes(h.ax_plate); cla; title('5. Detected Plate Region'); axis off;
        
        for k = 1:7
            axes(h.ax_chars{k}); cla; axis off;
        end
        
        guidata(hFig, h);
    end
end