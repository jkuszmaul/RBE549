function [cost] = evalObjects(image, objects, prevObjects)
  % Evaluate the object recognition for a given image:
  % Evaluates based on the following metrics:
  % Object deletion (i.e., the number of objects in
  %   prevObjects not in objects)
  % Number of objects in objects
  % Velocity accuracy: Comparison of velocity to the
  %   actual change between objects/prevObjects
  % Consistency: How much width/height changed
  % Blueness residual: For uncovered area, the
  %   less blue it is the higher the cost; for
  %   covered area, the more blue the worse.

  hue = image(:, :, 1);
  xscale = 1.0 / size(image, 2);
  yscale = 1.0 / size(image, 1);

  % Compute number of deleted objects
  objlabels = [];
  for i = 1:numel(objects)
    objlabels = [objlabels objects{i}.label];
  end

  prevlabels = [];
  ndeleted = 0;
  for i = 1:numel(prevObjects)
    if all(prevObjects{i}.label ~= objlabels)
      ndeleted = ndeleted + 1;
    end
    prevlabels = [prevlabels prevObjects{i}.label];
  end

  % Compute number of objects
  nobjects = numel(objects);

  % Compute velocity and width/hight change errors
  velcost = 0;
  widthcost = 0;
  heightcost = 0;
  % Mask corresponding to where object bounding boxes are:
  coveredarea = zeros(size(hue));

  for i = 1:nobjects
    obj = objects{i};
    previ = find(prevlabels == obj.label);

    minxi = max([1 ceil((obj.pos(1, 1) - obj.width / 2) / xscale)]);
    maxxi = min([size(hue, 2) ceil((obj.pos(1, 1) + obj.width / 2) / xscale)]);
    minyi = max([1 ceil((obj.pos(2, 1) - obj.height / 2) / yscale)]);
    maxyi = min([size(hue, 1) ceil((obj.pos(2, 1) + obj.height / 2) / yscale)]);
    coveredarea(minyi:maxyi, minxi:maxxi) = 1;

    if numel(previ) == 0
      continue
    end

    % This is an absolutely atrocious way to estimate velocity error--
    % the noise in the position will be far too great to provide a
    % meaningful result; we need to do filtering of position in order
    % to be able to actually use it as a reference.
    prevObj = prevObjects{previ};
    avgvel = mean([prevObj.vel obj.vel], 2);
    dpos = (obj.pos(:, 1) - obj.pos(:, end)) / (size(obj.pos, 2) - 1);
    verr = norm(avgvel - dpos);

    velcost = velcost + verr;

    dwidth = abs(obj.width - prevObj.width);
    dheight = abs(obj.height - prevObj.height);
    widthcost = widthcost + dwidth;
    heightcost = heightcost + dheight;
  end

  % And compute blueness costs:
  ignore = zeros(size(hue));
  ignore(1:ceil(0.6 * end), :) = 1; % Ignore top >half of image
  blue = 0.594;
  blueres = (hue - blue).^2;
  % Cost of non-blue areas not covered by objects:
  uncovered = ignore .* ~coveredarea;
  nonbluecost = sum(sum(blueres .* uncovered)) / sum(uncovered(:));
  % For now, don't compute blue areas covered by objects

  % For weights:
  % ndeleted: On order of zero to +5
  % nobjects: On order of zero to +20
  % velcost: On order of 5e-2
  % widthcost, heightcost: On order of 3e-2
  % nonbluecost: On order of 1e-2

  Kdel = 1;
  Knobj = 0.1;
  Kvel = 100;
  Kdim = 20;
  Kblue = 300;
  cost = Kdel * ndeleted + Knobj * nobjects + Kvel * velcost +...
         Kdim * (widthcost + heightcost) + Kblue * nonbluecost;
end
