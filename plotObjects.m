function plotObjects(objects, imsize)
  % For quiver plot:
  x = [];
  y = [];
  u = [];
  v = [];
  color = 'c';
  for i = 1:numel(objects)
    obj = objects{i};
    posx = ceil(obj.pos(1) * imsize(2));
    posy = ceil(obj.pos(2) * imsize(1));
    width = obj.width * imsize(2);
    height = obj.height * imsize(1);
    velx = obj.vel(1) * imsize(2);
    vely = obj.vel(2) * imsize(1);

    x = [x posx];
    y = [y posy];
    u = [u velx];
    v = [v vely];

    lstyle = '-';
    if obj.confidence < 0.5
      lstyle = ':';
    end
    rectangle('Position', [posx - width / 2 posy - height / 2 width height], 'LineStyle', lstyle, 'EdgeColor', color);
  end
  if numel(x) > 0
    scale = 3;
    quiver(x, y, scale * u, scale * v, color);
  end
end
