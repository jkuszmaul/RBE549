function objects = findFlowObj(flow, prevObjects, isinit)
% flow is an opticalFlow objects
% objects is a (possibly zero-length) vector of
% objects from the previous frame.
% isinit: Whether or not this is the first
% iteration (i.e., whether or  not we should
% pay attention to the fact that we may have zero
% objects).
% Individual object structure:
% pos: [x y] location of center (NOT in pixels, but in camera frame)
% vel: [x y] time derivative of position
% size: [width length] Assume rectangle; size in x/y directions
% confidence: 0-1 confidence of existence.

% First, we need to compute the nominal flow so that
% we can subtract out the water. In order to do this,
% we fit a simple, 5-parameter model to the
% provided flow data in a large region that should
% be mostly water (of course, this fails if we can't see
% any water), and subtract it out of the entire bottom
% half of the FOV:

% The ranges, in frame coordinates (x=[0,1], y=[0, 1]), over which we should fit the model:
% Note that we are ignoring the left portion of the screen,
% because that contains the top of the boat ladder:

xscale = 1.0 / size(flow.Vx, 2);
yscale = 1.0 / size(flow.Vy, 1);

% Update all the pre-existing objects using their
% velocities, and figure out the highest objectlabel
nextlabel = 0;
for i = 1:numel(prevObjects)
  prevObjects{i}.pos = prevObjects{i}.pos + prevObjects{i}.vel;
  nextlabel = max(prevObjects{i}.label+1, nextlabel);
end

xfitrange = ceil([0.2 1] / xscale);
yfitrange = ceil([0.45 1] / yscale);

useRegions = ones(size(flow.Vx));
useRegions(1:floor(0.45 * end), :) = 0; % Ignore sky
% Very bottom of screen too close to boat
useRegions(floor(0.8 * end):end, :) = 0;
% Boat ladder
useRegions(floor(0.75 * end):end, 1:floor(0.2 * end)) = 0;

tic
[nomVx, nomVy] = fitFlow(flow.Vx, flow.Vy, xfitrange, yfitrange);
toc
diffVx = flow.Vx - nomVx;
diffVy = flow.Vy - nomVy;
diffMag = sqrt(diffVx.^2 + diffVy.^2);

tic
threshold = 3.0; % Magnitude

bwthresh = useRegions .* diffMag > threshold;
se = strel('disk', 5);
bwthresh = imerode(bwthresh, se);
se = strel('disk', 10);
bwthresh = imdilate(bwthresh, se);

minobjsize = 500;
[labeled, nobj] = bwlabel(bwthresh);
objremain = [];
for i = 1:nobj
  % Remove objects of insufficient size
  object = labeled == i;
  objsize = sum(object(:));
  if objsize < minobjsize
    labeled(object) = 0;
  else
    objremain = [objremain i];
  end
end
toc

% Compute the velocity/bounding box for each measured
% object
objects = {};
for i = objremain
  object = labeled == i;
  xs = find(sum(object, 1));
  ys = find(sum(object, 2));
  minx = (min(xs) - 1) * xscale;
  maxx = (max(xs) - 1) * xscale;
  miny = (min(ys) - 1) * yscale;
  maxy = (max(ys) - 1) * yscale;
  obj.width = maxx - minx;
  obj.height = maxy - miny;
  obj.pos = [mean([minx maxx]); mean([miny maxy])];

  vxs = flow.Vx(object) * xscale;
  vys = flow.Vy(object) * yscale;

  obj.vel = [median(vxs); median(vys)];

  obj.confidence = 0.2 + isinit * 0.5;

  obj.label = -1;
  % Go through previous objects and try to identify objects that go with this one
  usedi = [];
  for i = 1:numel(prevObjects)
    prev = prevObjects{i};
    dpos = obj.pos - prev.pos;
    dvel = obj.vel - prev.vel;
    dwidth = obj.width - prev.width;
    dheight = obj.height - prev.height;
    sizenorm = hypot(dwidth, dheight);
    velnorm = norm(dvel) / norm(obj.vel);
    posnorm = norm(dpos);
    postol = 0.5 * hypot(obj.width, obj.height);
    if sizenorm < 0.2 && velnorm < 0.8 && posnorm < postol
      Kfilt = 0.9;
      obj.pos = Kfilt * obj.pos + (1 - Kfilt) * prev.pos;
      obj.vel = Kfilt * obj.vel + (1 - Kfilt) * prev.vel;
      obj.width = Kfilt * obj.width + (1 - Kfilt) * prev.width;
      obj.height = Kfilt * obj.height + (1 - Kfilt) * prev.height;
      % If we accumulate multiple previous objects,
      % throw out old labels
      obj.label = prev.label;
      K = 0.2;
      obj.confidence = (1 - K) * prev.confidence + K;
      usedi = [usedi i];
    end
  end
  % Get rid of assigned previous objects:
  prevObjects(:, usedi) = [];

  % If we couldn't associated with a previous object,
  % assign ourselves a label:
  if obj.label == -1
    obj.label = nextlabel;
    nextlabel = nextlabel + 1;
  end

  objects = [objects obj];
end

% Go through the previous objects and lower their
% confidences, throwing them out if the confidence
% gets lowered too much.
for i = 1:numel(prevObjects)
  obj = prevObjects{i};
  obj.confidence = obj.confidence - 0.1;
  if obj.confidence > 0
    objects = [objects obj];
  end
end

end
