test_img = im2double(imread('./data/vlcsnap-boat.png'));
%test_img = im2double(imread('./data/vlcsnap-boat-far.png'));
%test_img = im2double(imread('./data/vlcsnap-buoy.png'));
im_size = size(test_img);

test_img_hsv = rgb2hsv(test_img);
test_img_gray = rgb2gray(test_img);
test_img_gray_small = imresize(test_img_gray, 0.25);

%% HSV Segmentation

h = reshape(test_img_hsv(:,:,1), 1, im_size(1)*im_size(2));
s = reshape(test_img_hsv(:,:,2), 1, im_size(1)*im_size(2));
v = reshape(test_img_hsv(:,:,3), 1, im_size(1)*im_size(2));

figure();
subplot(3,1,1);
scatter(h,s, '.');
subplot(3,1,2);
scatter(s,v, '.');
subplot(3,1,3);
scatter(v,h, '.');

figure();
subplot(3,1,1);
hist(h);
subplot(3,1,2);
hist(s);
subplot(3,1,3);
hist(v);

figure();
scatter3(h,s,v, '.');

%% Do a k means clustering
classes = kmeans([h',s',v'], 2);

% Show the different classes
class_img = reshape(classes, im_size(1), im_size(2));
figure();
subplot(2,1,1);
imshow(test_img);
subplot(2,1,2);
imagesc(class_img);

%% See what entropy filtering does
en_img = entropyfilt(test_img_gray);
std_img = stdfilt(test_img_gray);
range_img = rangefilt(test_img_gray);

figure();
subplot(2,2,1);
imshow(test_img);
subplot(2,2,2);
imagesc(en_img); title('EN');
subplot(2,2,3);
imagesc(std_img); title('STD');
subplot(2,2,4);
imagesc(range_img); title('RNG');

%%
figure();
subplot(2,2,1);
imshow(test_img);
subplot(2,2,2);
comb = en_img.*std_img.*range_img;
imagesc(en_img.*std_img.*range_img);
subplot(2,2,3);
imagesc(imgaussfilt(comb, 4));
subplot(2,2,4);
imagesc(imgaussfilt(comb, 8));

%% Test Gabor Filter
wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(im_size(1), im_size(2));
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);

g = gabor(wavelength, orientation);
gabormags = imgaborfilt(test_img_gray_small, g);

%% Show the gabor images
num_filts = size(gabormags, 3);
figure();
for i=1:num_filts
    subplot(4,8,i);
    imagesc(gabormags(:,:,i));
end

%% Post process the gabor images
gabormag = gabormags(:,:,:);
numRows = size(test_img_gray_small, 1);
numCols = size(test_img_gray_small, 2);
for i = 1:length(g)
    sigma = 0.5*g(i).Wavelength;
    K = 3;
    gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
end

X = 1:numCols;
Y = 1:numRows;
[X,Y] = meshgrid(X,Y);
featureSet = cat(3,gabormag,X);
featureSet = cat(3,featureSet,Y);

numPoints = im_size(1)*im_size(2);
X = reshape(featureSet,numRows*numCols,[]);

X = bsxfun(@minus, X, mean(X));
X = bsxfun(@rdivide,X,std(X));

coeff = pca(X);
feature2DImage = reshape(X*coeff(:,1),numRows,numCols);
figure
imshow(feature2DImage,[])

%% Test on Video
%vidReader = VideoReader('./data/boat.mp4');
vidReader = VideoReader('./data/GP060042.MP4');
vidReader.CurrentTime = 10 * 60 + 48;
%vidReader.CurrentTime = 14*60;

% Do a kmeans cluster on the first image for segmentation
first_frame = readFrame(vidReader);
hsv_frame = rgb2hsv(first_frame);
frame_size = size(first_frame);
[classes clusters] = kmeans([reshape(hsv_frame(:,:,1),frame_size(1)*frame_size(2),1) ...
                             reshape(hsv_frame(:,:,2),frame_size(1)*frame_size(2),1) ...
                             reshape(hsv_frame(:,:,3),frame_size(1)*frame_size(2),1)], 2);
% Figure out which class is the water by counting the number of classes in
% the bottom half of the frame
class_frame = reshape(classes, frame_size(1), frame_size(2));
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

% Show the classification results
figure();
imagesc(reshape(classes, frame_size(1), frame_size(2)));

%%
i = 0;
figure();
num_frames = 30;
all_frames = zeros(frame_size(1)/2*frame_size(2)/2, num_frames);
while hasFrame(vidReader) && i < num_frames
    frameRGB = readFrame(vidReader);
    % Calculate the classified image
    tmp = rgb2hsv(imresize(frameRGB,0.5));
    [classes, dists] = hsvClassify(rgb2hsv(imresize(frameRGB,0.5)), clusters);
    all_frames(:,i+1) = classes;
    tmp_img = reshape((classes==2).*(dists.^2), frame_size(1)/2, frame_size(2)/2);
    %tmp_img(1:end/2, :) = 0;
    imagesc(tmp_img);
    i = i+1; 
    %pause(0.02);
end

%% Test temporal filtering
figure();
temp_filt_img = reshape(sum(all_frames, 2)./(2*num_frames), frame_size(1)/2, frame_size(2)/2);
subplot(2,2,1);
imshow(temp_filt_img); title('Temporal class sum (60 frames)');
subplot(2,2,2);
imshow(temp_filt_img > 0.5+(0.5/2)); title('>50%');
subplot(2,2,3);
imshow(temp_filt_img > 0.5+(0.75/2)); title('>75%');
subplot(2,2,4);
imshow(temp_filt_img > 0.5+(0.25/2)); title('>25%');