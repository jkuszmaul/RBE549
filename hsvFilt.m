function [confidence_image] = hsvFilt(hsv_img, clusters)
    % Calculate the classified image
    disp('New Frame');
    tic
    img_size = size(hsv_img);
    [classes, dists] = hsvClassify(hsv_img, clusters);
    toc
    confidence_image = reshape((classes==2).*(dists.^2), img_size(1), img_size(2));
    toc
    % Suppress the sky region
    sky_area = bwareaopen(reshape(classes==2, img_size(1), img_size(2)), img_size(1)*img_size(2)/4);
    confidence_image(sky_area==1) = 0;
    toc
end
