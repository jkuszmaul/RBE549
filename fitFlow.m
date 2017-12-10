function [expVx, expVy] = fitFlow(Vx, Vy, xrange, yrange)
% Formulas:
% vc = Boat velocity
% Vx, Vy = measured optical flow
% vz = czdot
% cz = z position of camera
% Kalpha = 2 * sin(theta / 2), where theta=vertical FOV angle
% pf = position of point in frame
% xf, yf = components of pf, yf ranges -0.5 to 0.5
%   from bottom to top of frame; xf is -8/9 to +8/9
% pfdot_x = -vc * Kalpha / cz * xf * yf
% pfdot_y = vz / cz * yf - vz * Kalpha / cz * yf^2
% In the linear problem, this gives us
% several constants that we would like to find:
% Kalpha / cz
% vz / cz
% vz * Kalpha / cz
% If there is a constant offset in y, then
% we can ignore the exact mechanics of some
% of the constants and say:
% pfdot_x = a * xf * yf + b * xf
% pfdot_y = c * yf^2 + d * yf + e
% Least squares problem:
% Ax = b
% x = [a b c d e]'
% b = [Vx(1) Vx(2) Vx(3)... Vx(end) Vy(1) ... Vy(end)]'
expVx = zeros(size(Vx));
expVy = zeros(size(Vy));

pfy = repmat(linspace(-0.5, 0.5, size(Vx, 1))', 1, size(Vx, 2));
aspect = size(Vx, 2) / size(Vx, 1);
pfx = repmat(linspace(-aspect / 2, aspect / 2, size(Vx, 2)), size(Vx, 1), 1);

Nfull = numel(Vx);
Nzero = zeros(Nfull, 1);
Afull = [pfx(:) .* pfy(:) pfx(:) Nzero Nzero Nzero;
         Nzero Nzero pfy(:).^2 pfy(:) (Nzero + 1)];
bfull = [Vx(:);
         Vy(:)];

limrange = @(mat) mat(yrange(1):yrange(2), xrange(1):xrange(2));
pfx = limrange(pfx);
pfy = limrange(pfy);
Vx = limrange(Vx);
Vy = limrange(Vy);

pfx = pfx(:);
pfy = pfy(:);

useobv = 1:3:numel(pfx);
pfx = pfx(useobv);
pfy = pfy(useobv);
Vx = Vx(useobv);
Vy = Vy(useobv);

N = numel(Vx);
Nzero = zeros(N, 1);
A = [pfx .* pfy pfx Nzero Nzero Nzero;
     Nzero Nzero pfy.^2 pfy (Nzero + 1)];
b = [Vx(:);
     Vy(:)];
%x = A \ b;
tic
model = fitlm(A, b);%, 'RobustOpts', 'on');
toc
%calcres = @(A, b, x) (A * x - b).^2;
%res = calcres(A, b, x);

%figure;
%hist(res)
%title('Histogram of residuals');

Nfull
%expVx = reshape(Afull(1:Nfull, :) * x, size(expVx));
%expVy = reshape(Afull(Nfull+1:end, :) * x, size(expVy));
expvals = predict(model, Afull);
expVx = reshape(expvals(1:Nfull), size(expVx));
expVy = reshape(expvals(Nfull+1:end), size(expVy));
end
