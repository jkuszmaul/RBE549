function [clusters, class_image] = getHSVClusters(rgb_image)
    image_size = size(rgb_image);
    hsv_frame = rgb2hsv(rgb_image);
    
    [classes clusters] = kmeans([reshape(hsv_frame(:,:,1),image_size(1)*image_size(2),1) ...
                             reshape(hsv_frame(:,:,2),image_size(1)*image_size(2),1) ...
                             reshape(hsv_frame(:,:,3),image_size(1)*image_size(2),1)], 2);
                         
    % Figure out which class is the water by counting the number of classes in
    % the bottom half of the frame
    class_frame = reshape(classes, image_size(1), image_size(2));
    bottom_classes = reshape(class_frame(end/2:end,:),size(class_frame(end/2:end,:),1)*size(class_frame(end/2:end,:),2),1);
    class1_count = sum(bottom_classes == 1);
    class2_count = sum(bottom_classes == 2);
    [num, water_class] = max([class1_count, class2_count]);

    % Force the water class to be 1
    if water_class==2
        disp('swapping');
        water_class==1;
        classes(classes==2) = 3;
        classes(classes==1) = 2;
        classes(classes==3) = 1;
        tmp = clusters(2,:);
        clusters(2,:) = clusters(1,:);
        clusters(1,:) = tmp;
    end
    
    class_image = reshape(classes, image_size(1), image_size(2));
end