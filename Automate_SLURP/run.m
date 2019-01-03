%% Automate SLURP
% 2018-11-30 Jaekoo
%
% This script helps automate tongue contour tracking procedure in SLURP
% without GUI interface. Especially, if you have a seed frame, this script
% will make SLURP generate automatic contour tracking for the subsequent
% frames and easily save the contours as GetContour compatible format.
%
% **Note
% - Run this script under Automate_SLURP directory
% - You need to prepare .avi files.
% - You need to prepare a seed frame for each .avi file (eg., first frame as seed).

close all;clear;clc

%% Settings
% Path
slurp_dir = '/Users/jaegukang/GoogleDrive/GitHub/SLURP';
addpath(slurp_dir);
output_dir = './output';
seed_out_dir = './seed';
interp_points = 100;

% Load video files
video_dir = '/Volumes/Transcend/_DataArchive/ICPhS2019_AdultData_Russian_Ultrasound_from_Boram'; % adults
% video_dir = '/Volumes/Transcend/_DataArchive/ICPhS2019_KidData_Ghada_Child_AutoContoursAVI_Nov2018'; % kids
dt = dir(video_dir);
dtnames = {dt.name};
idx = ~cellfun(@isempty, regexp(dtnames, '.avi'));
dtnames = dtnames(idx);
if isempty(dtnames); error('no avi files found'); end

%% Load seed frames
seed_dir = '/Users/jaegukang/GoogleDrive/_Project/_2018-10_-_Ultrasound_Compare_Metrics/Boram/every_fifth_frame_manual';
% seed_dir = '/Users/jaegukang/GoogleDrive/_Project/_2018-10_-_Ultrasound_Compare_Metrics/Rion/every_fifth_frame_manual_kid';
for i = 1:length(dtnames)
    seed_file = fullfile(seed_dir, regexprep(dtnames{i}, '.avi', '.mat'));
    % Make seed files under 'seed' folder
    make_seed_frame(seed_file , seed_out_dir)
end
disp('Seeds were created.')

%% Run
% Iterate over files
for i = 1:length(dtnames)
    t = datestr(datetime('now')); % get current time
    fprintf('%d/%d %s at % s\n',i,length(dtnames),dtnames{i},t)
    
    video_file = fullfile(video_dir, dtnames{i});
    seed_file = fullfile(seed_out_dir, regexprep(dtnames{i}, '.avi', '.mat'));
    
    % Load
    S = load_SLURP(video_file, seed_file, slurp_dir);
    % Fit snake (for the initial frame only)
    S = fit_snake_SLURP(S);
    % Fit snake with particle filtering (for all frames)
    S = fit_snake_particle_filtering_SLURP(S);
    % Interpolate to 100 points
    S = interpolate_SNAKE(S, interp_points);
    % Save as GetContour compatible format
    save_contour_SLURP(S, output_dir); 
end
t = datestr(datetime('now')); % get current time
fprintf('All saved at %s\n', t);
