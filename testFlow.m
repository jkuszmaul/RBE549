function testFlow()
  close all;
  opticFlow = opticalFlowLK('NoiseThreshold',0.009);
  opticFlow = opticalFlowHS;
  opticFlow = opticalFlowFarneback;
  [vidReader, speeds] = loadVids();
  vidReader.CurrentTime = 10 * 60 + 46;
  i = 0;
  objects = {};
  while hasFrame(vidReader) && i < 150
    tic
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    toc

    tic
    flow = estimateFlow(opticFlow,frameGray);
    toc

    tic
    objects = findFlowObj(rgb2hsv(frameRGB), flow, objects, i == 0);
    toc

    tic
    imshow(frameRGB);
    hold on;
    plotObjects(objects, size(flow.Vx));
    hold off;
    drawnow;
    pause(0.25);
    toc

    i = i + 1
  end

  [expVx, expVy] = fitFlow(flow.Vx, flow.Vy, ceil(432 * [0.25, 1]), ceil(240 * [0.5, 1]));
  expFlow = opticalFlow(expVx, expVy);

  diffVx = flow.Vx - expVx;
  diffVy = flow.Vy - expVy;
  diffFlow = opticalFlow(diffVx, diffVy);

  figure;
  imshow(frameRGB)
  hold on
  plot(flow,'DecimationFactor',[10 10],'ScaleFactor',3)
  q = findobj(gca,'type','Quiver');
  q.Color = 'r';
  hold off
  figure;
  imshow(frameRGB)
  hold on
  plot(diffFlow,'DecimationFactor',[10 10],'ScaleFactor',3)
  q = findobj(gca,'type','Quiver');
  q.Color = 'r';
  plotObjects(objects, size(flow.Vx));
  title('DiffFlow');
  hold off
  figure;
  imshow(frameRGB)
  hold on
  plot(expFlow,'DecimationFactor',[10 10],'ScaleFactor',3)
  q = findobj(gca,'type','Quiver');
  q.Color = 'r';
  hold off
  figure;
  imagesc(diffFlow.Vx, [-8 8]);
  title('Diff Flow X');
  figure;
  imagesc(flow.Vx, [-8 8]);
  title('Flow X');
  figure;
  imagesc(diffFlow.Vy, [-8 8]);
  title('Diff Flow Y');
  figure;
  imagesc(flow.Vy, [-8 8]);
  title('Flow Y');
  figure;
  imagesc(diffFlow.Magnitude, [0 15]);
  title('Diff Magnitude');
  figure;
  imagesc(flow.Magnitude, [0 15]);
  title('Magnitude');
  figure;
  imagesc(flow.Orientation);
  title('Orientation');
  figure;
  imshow(frameRGB);
  title('Image');
  figure;
  hsv = rgb2hsv(frameRGB);
  blues = reshape(hsv(ceil(0.5 * end):end, [ceil(0.4 * end):end], 1), 1, []);
  blue = mean(blues)
  stdblue = std(blues) / 1
  isblue = (hsv(:, :, 1) > (blue + 3 * stdblue)) + (hsv(:, :, 1) < (blue - 3 * stdblue));
  imshow(hsv(:, :, 1));
  title('Hue');
  figure;
  imshow(isblue)
  title('Is not Blue');
  figure;
  se = strel('disk',5);
  isblue = imerode(isblue, se);
  se = strel('disk',15);
  isblue = imdilate(isblue, se);
  imshow(label2rgb(bwlabel(isblue), 'hsv', 'k', 'shuffle'))
  title('Is not Blue bwlabel');
  figure;
  imshow(hsv(:, :, 2));
  title('Saturation');
  figure;
  imshow(hsv(:, :, 3));
  title('Value');

  return
  hold on
  imshow(frameRGB)
  plot(newFlow,'DecimationFactor',[3 3],'ScaleFactor',10)
  figure;
  imshow(frameGray * 0.1)
  hold on;
  plot(newFlow,'DecimationFactor',[3 3],'ScaleFactor',10)
  figure;
end
