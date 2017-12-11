function [confidence_image] = wakeSuppress(hsv_frame)
  confidence_image = 1-(1-hsv_frame(:,:,2)).*hsv_frame(:,:,3).*entropyfilt(hsv_frame(:,:,3));
end
