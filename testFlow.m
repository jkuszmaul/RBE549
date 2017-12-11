function testFlow()
  close all;
  opticFlow = opticalFlowLK('NoiseThreshold',0.009);
  opticFlow = opticalFlowHS;
  opticFlow = opticalFlowFarneback();
  [vidReader, speeds] = loadVids();
  vidReader.CurrentTime = 10 * 60 + 46; % For GP060042 boat
%  vidReader.CurrentTime = 6 * 60 + 30; % For GP010041 kayak
%  vidReader.CurrentTime = 0 * 60 + 5; % For GP010041 start
%  vidReader.CurrentTime = 2 * 60 + 17; % For GP020042 boat
  i = 0;
  objects = {};
  prevObjects = {};
  costs = [];
  clusters = [];
  while hasFrame(vidReader) && i < 150
    tic
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    toc
    if numel(clusters) == 0
      clusters = getHSVClusters(frameRGB);
    end

    tic
    flow = estimateFlow(opticFlow,frameGray);
    toc

    frameHSV = rgb2hsv(frameRGB);

    tic
    objects = findFlowObj(frameHSV, flow, objects, clusters, i == 0);
    toc

    tic
    imshow(frameRGB);
    hold on;
    plotObjects(objects, size(flow.Vx));
    hold off;
    drawnow;
    toc

    pause(0.25);
    tic
    cost = evalObjects(frameHSV, objects, prevObjects)
    toc
    costs = [costs cost];

    prevObjects = objects;
    i = i + 1
  end
  costs
  sum10toend = sum(costs(10:end))
  return

  [expVx, expVy] = fitFlow(flow.Vx, flow.Vy, ceil(1920 * [0.25, 1]), ceil(1080 * [0.5, 1]));
  expFlow = opticalFlow(expVx, expVy);

  diffVx = flow.Vx - expVx;
  diffVy = flow.Vy - expVy;
  diffFlow = opticalFlow(diffVx, diffVy);

  figure;
  imshow(frameRGB)
  hold on
  plot(flow,'DecimationFactor',[30 30],'ScaleFactor',5)
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
