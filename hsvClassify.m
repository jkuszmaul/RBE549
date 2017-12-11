function [classes] = hsvClassify(hsv_img, clusters)
    img_size = size(hsv_img);
    classes = zeros(img_size(1)*img_size(2),1);
    % Linearize the image
    pixels = [reshape(hsv_img(:,:,1), img_size(1)*img_size(2),1) ...
             reshape(hsv_img(:,:,2), img_size(1)*img_size(2),1) ...
             reshape(hsv_img(:,:,3), img_size(1)*img_size(2),1)];
    for i=1:img_size(1)*img_size(2);
        % Find the closest cluster for each pixel
        dists = sqrt(sum((clusters - pixels(i,:)).^2,2));
        [dist, classes(i)] = min(dists);
    end
end