function [gray_img, binary_img, filtered_img, edge_img, enhanced_img] = preprocess_image(img)

    if size(img, 3) == 3
        gray_img = rgb2gray(img);
    else
        gray_img = img;
    end

    filtered_img = medfilt2(gray_img, [3 3]);

    enhanced_img = adapthisteq(filtered_img);

    level = graythresh(enhanced_img);
    binary_img = imbinarize(enhanced_img, level);

    edge_img = edge(enhanced_img, 'canny');

    se = strel('rectangle', [2, 3]);
    edge_img = imclose(edge_img, se);

end