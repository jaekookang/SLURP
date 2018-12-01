function make_seed_frame(seed_file, output_dir)
% This function make seed file for SLURP by extracting only the first frame
% from the manually tracked file (e.g., .mat file GetContour compatible format)
%
% 2018-11-30 Jaekoo
%
% TODO: Add options to choose frame number. Now it only reads the first
% frame as a seed.

if exist(seed_file) == 0; error('%s does not exist', seed_file); end
if exist(output_dir) == 0; mkdir(output_dir); end

[path,fid,ext] = fileparts(seed_file);

M = load(seed_file);
M = getfield(M, fid);

seed_frame = 1;
initialization = struct('anchors',M(seed_frame).ANCHORS,'frame',seed_frame);

try
    save_file_path = fullfile(output_dir, strcat(fid, '.mat'));
    save(save_file_path, 'initialization');
catch ME
    fprintf('Saving %s has failed\n', save_file_path);
    warning(ME);
end
    