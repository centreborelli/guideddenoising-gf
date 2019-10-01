#!/usr/bin/env octave -qfW

% Apply the guided filter
%
% 2019, Charles Hessel, CMLA, ENS Paris-Saclay


pkg load image
arg_list = argv();


%%% Add files to path (so that script can be called from outside its directory)
[scriptPath, scriptName, scriptExt] = fileparts(mfilename('fullpath'));
addpath(scriptPath)
addpath([scriptPath '/iio'])


%%% Read/Check parameters
usage = sprintf([...
  '%s/%s%s input guide output epsilon radius\n' ...
  '- input  : path to input image\n' ...
  '- guide  : path to guide image use "NULL" if no guide\n' ...
  '- output : path to output *directory* (created if needed)\n' ...
  '- sqrteps: square-root of epsilon: amount of smoothing, in (0,255]\n' ...
  '- radius : patch size = (2*radius+1)^2\n'], ...
  scriptPath, scriptName, scriptExt);

if nargin == 0, fprintf(usage); quit; end
if nargin < 5, error('Missing argument(s).\nUsage:\n%s\n', usage);
else
  u_path = arg_list{1};
  g_path = arg_list{2};
  outdir = arg_list{3};
  sqrteps = str2double(arg_list{4});
  radius = str2double(arg_list{5});
end
if strcmpi(g_path, 'null'), g_path = []; end


%%% Read the input images
u = double(iio_read(u_path) / 255);
if ~isempty(g_path)
  g = double(iio_read(g_path) / 255);
  if size(u) ~= size(g)
    error('input and guide''s sizes are not consistent\n');
    quit;
  end
  u = cat(3, u, g);
end


%%% Create the output directory, prepare filename for filtered image
if ~exist(outdir, "dir")
  mkdir(outdir);
end
[im_path, im_name, im_ext] = fileparts(u_path);
v_path = [outdir '/' im_name '.tif'];


%%% Apply the filter
v = gf_multichannel(u, (sqrteps / 255)^2, radius);


%%% Save the output
if ~isempty(g_path)
  iio_write(v_path, single(v(:, :, 1) * 255));  % both channels are filtered
else
  iio_write(v_path, single(v * 255));  % there is only one channel
end


%%% Display infos
fprintf(['input: %s \tguide: %s \t output: %s \t' ...
         '(sqrteps=%.1f, radius=%.1f)\n'], ...
  u_path, g_path, v_path, sqrteps, radius);

