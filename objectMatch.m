function [objects] = objectMatch(prevObjects, newObjects)
% Takes the previous set of objects (presumes that they HAVE been
% updated already so we don't need to set pos = pos + vel)

% Create distance matrices so that we have the distances between
% each pair of prev/new object and new/new object:
prevnewmat = zeros(numel(newObjects), numel(prevObjects));
% We will only use the area above the diagonal in newnewmat
newnewmat = zeros(numel(newObjects), numel(newObjects));
for i = 1:numel(newObjects)
  nobj = newObjects{i};
  for j = 1:numel(prevObjects)
    prevnewmat(i, j) = objdiff(nobj, prevObjects{j});
  end
  for j = i+1:numel(newObjects)
    newnewmat(i, j) = objdiff(nobj, newObjects{j});
  end
end

% Now, iterate through each object and combine itself
% with its neighbors, removing objects as they are
% gone over or assimilated. We should also check
% neighbors-of-neighbors and so on, but for now
% we want to avoid making too large of combinations
objects = {};
diffthresh = 1.5;
pnnear = prevnewmat < diffthresh;
nnnear = newnewmat < diffthresh;
usedprev = [];
usednew = [];
for i = 1:numel(newObjects)
  if any(i == usednew)
    continue;
  end
  previs = find(pnnear(i, :));
  newis = find(nnnear(i, :));
  usedprev = [usedprev previs];
  usednew = [usednew newis];
  % Prevent anyone else from claiming them as neighbors
  pnnear(:, previs) = 0;
  nnnear(:, newis) = 0;
  neighbors = {newObjects{i}};
  neighbors = [neighbors prevObjects{previs} newObjects{newis}];
  newobj = mergeobjects(neighbors);
  objects = [objects newobj];
end

% Remove the objects that we used
prevObjects(:, usedprev) = [];
newObjects(:, usednew) = [];

% Go through the previous objects and lower their
% confidences, throwing them out if the confidence
% gets lowered too much.
remove = [];
for i = 1:numel(prevObjects)
  obj = prevObjects{i};
  if obj.updated == 0
    prevObjects{i}.confidence = obj.confidence - 0.1;
    if obj.confidence < 0
      remove = [remove i];
    end
  end
end

prevObjects(:, remove) = [];

objects = [objects prevObjects newObjects];

end

function [obj] = mergeobjects(objects)
  % Performs merger of N objects
  obj.pos = [0; 0];
  obj.vel = [0; 0];
  obj.width = 0;
  obj.height = 0;
  obj.confidence = 0;
  obj.updated = 1;
  obj.texist = 0;
  obj.label = Inf;

  minx = 1.0;
  maxx = 0.0;
  miny = 1.0;
  maxy = 0.0;
  area = 0.0;
  pastposes = [];
  npastposes = [];
  for i = 1:numel(objects)
    nobj = objects{i};
    if ~nobj.updated
      % If a previous object, reduce width/height slightly
      % to avoid never-decreasing sizes
      nobj.width = nobj.width * 0.75;
      nobj.height = nobj.height * 0.75;
    end
    npos = nobj.pos(:, 1);
    minx = min([minx npos(1) - nobj.width / 2]);
    maxx = max([maxx npos(1) + nobj.width / 2]);
    miny = min([miny npos(2) - nobj.height / 2]);
    maxy = max([maxy npos(2) + nobj.height / 2]);

    obj.confidence = max([obj.confidence nobj.confidence]);
    obj.texist = max([obj.texist nobj.texist]);
    % Keep the oldest label possible
    obj.label = min([obj.label nobj.label]);

    % Combine velocities using weighted average by area
    narea = nobj.width * nobj.height;
    area = area + narea;
    obj.vel = obj.vel + nobj.vel * narea;

    % Combine past positions by straight-up averaging
    Nnew = size(nobj.pos, 2) - 1;
    Ncur = size(pastposes, 2);
    pastposes(:, Ncur+1:Nnew) = zeros(2, Nnew - Ncur);
    npastposes(:, Ncur+1:Nnew) = zeros(2, Nnew - Ncur);
    pastposes(:, 1:Nnew) = pastposes(:, 1:Nnew) + nobj.pos(:, 2:end);
    npastposes(:, 1:Nnew) = npastposes(:, 1:Nnew) + 1;
  end
  obj.vel = obj.vel / area;
  if numel(pastposes) > 0
    pastposes = pastposes ./ npastposes;
  end

  % Calculate new current position and size from min/max x/y
  newpos = mean([minx maxx;
                 miny maxy], 2);
  obj.pos = [newpos pastposes];
  obj.width = maxx - minx;
  obj.height = maxy - miny;

  % Boost the confidence of anything that we have combined
  K = 0.3;
  obj.confidence = (1 - K) * obj.confidence + K;

  % Compare the velocity to the change in position over the
  % past time:
  % TODO(james): This doesn't seem to have much effect...
  % Maybe instead just say that things that are bad beyond
  % a certain threshold gets a constant knock?
  nposes = size(obj.pos, 2);
  if nposes > 10
    pos = obj.pos(:, 1)
    vel = obj.vel
    dpos = (obj.pos(:, 1) - obj.pos(:, end)) / (nposes - 1);
    normvel = norm(dpos - obj.vel) / max(norm(obj.vel), norm(dpos))
    change = 0.0;
    if normvel > 1.2
      change = -0.2;
    elseif normvel < 0.8
      change = 0.0;
    end
    obj.confidence = min(obj.confidence + change, 1);
  end
end

function [diff] = objdiff(obj1, obj2)
% Returns a conception difference between two objects.
% Zero suggests identical; positive values are more different
[magnorm, angnorm] = veldiff(obj1.vel, obj2.vel);
posnorm = posdiff(obj1.pos, obj2.pos, obj1.width, obj2.width,...
                  obj1.height, obj2.height);
diff = (1 - magnorm) + angnorm + posnorm;
end

function [magnorm, angnorm] = veldiff(v1, v2)
% Computes normalized difference between v1 and v2
% magnorm will range from 0 (one of v1/v2 is infinitely larger than the other)
%   1 (identical speeds)
% angnorm = absolute value of difference, in radians,
%   between the directions of the velocities
  s1 = norm(v1);
  s2 = norm(v2);
  theta1 = atan2(v1(2), v1(1));
  theta2 = atan2(v2(2), v2(1));

  mins = min([s1 s2]);
  maxs = max([s1 s2]);
  magnorm = -1.0;
  angnorm = 0.0;
  % Avoid situations with near-zero denominators
  if maxs > 1e-8
    magnorm = mins / maxs;
    angnorm = abs(angdiff(theta1, theta2));
  end
end

function [posnorm] = posdiff(p1, p2, w1, w2, h1, h2)
% Returns the difference, normalizes to rectangle size,
% between two points, such that if the rectangles were
% touching on corners, we would return sqrt(2) (normalized
% to x and y diffs would be thought of as one).
  dx = (p1(1) - p2(1)) / mean([w1 w2]);
  dy = (p1(2) - p2(2)) / mean([h1 h2]);
  posnorm = hypot(dx, dy);
end
