# HSV Segmentation
HSV segmentation does ok for a very controlled image, but of course has problems with wave caps.  Trained a 2 class k-means classifier, and it does a really good job of segmenting the land from the sky.  Also picks out some different objects in the water, and ocasionally wave tips.  Could temporally filter the state with a hysterisis trigger (like schmidt) based on class.
hsv_kmeans2.jpg

# Entropy Filtering
Sometimes objects have more local entropy than their immediate surroundings with a 9 pixel window.

entropy_filt.jpg

# Entropy Filtering with Std Dev and Range filtering
Get better results by point-wise multiplying the resulting images of the Entropy Std Deviation, and Range filters with a gaussian blur to get rid of large localmaximums in the waves. Top right: no gaussian blur and image values scaled. Bottom left: gaussian blur sigma = 4 and image values scaled.  Bottom Right: gaussian blur sigma=8 and image values scaled.

entropy_combined.jpg

# Texture filtering with Gabor filters
Compute gabor features and filter results on the image. (image bank of several frequencies, and orientations). Takes a long time to process the image though, and will not be good for real-time processing.  Could combine with filter bank concept and image scaling.  Use the post-processing techniques to get a decent segmentation result.

gabor_banks.jpg
gabor_result.jpg


