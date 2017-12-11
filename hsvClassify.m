function [classes] = hsvClassify(hsv_img, clusters)
    img_size = size(hsv_img);
    class_dists = zeros(img_size(1)*img_size(2), 2);
    % Linearize the image
    pixels = [reshape(hsv_img(:,:,1), img_size(1)*img_size(2),1) ...
             reshape(hsv_img(:,:,2), img_size(1)*img_size(2),1) ...
             reshape(hsv_img(:,:,3), img_size(1)*img_size(2),1)];
         
    % Compare the distances and classify
    class_dists(:,1) = sqrt(sum((pixels - clusters(1,:)).^2,2));
    class_dists(:,2) = sqrt(sum((pixels - clusters(2,:)).^2,2)); 
    [dists, classes] = min(class_dists, [], 2);
end