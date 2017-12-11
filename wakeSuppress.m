function [confidence_image] = wakeSuppress(rgb_image)
  hsv_frame = rgb2hsv(rgb_image);
  confidence_image = 1-(1-hsv_frame(:,:,2)).*hsv_frame(:,:,3).*((entropyfilt(rgb2gray(rgb_image)/8).^2));
end