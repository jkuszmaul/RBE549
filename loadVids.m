function [vid, speeds] = loadVids()
  name = 'GP060042';
  name = 'GP010041';
  name = 'GP020042';
  vid = VideoReader(['/media/james/builtin1/10-20-video/' name '.MP4']);
  speeds = []
%  speeds = readtable(['process-nmea/' name '.csv']);
%  speeds = table2array(speeds);
  % Normalize speeds
%  speeds(:, 1) = speeds(:, 1) - speeds(1, 1);
end
