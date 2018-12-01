function save_contour_SLURP(state, save_dir)
% This function saves state as .mat file (GetContour compatible format)
% 2018-11-30 Jaekoo

[path,video_id,ext] = fileparts(state.VIDEO_NAME);

mat.XY = [];
mat.ANCHORS = [];
mat.FRAME = [];
mat.NOTE = [];
mat.TRKRES = [];
mat.TIME = [];
mat.IMAGE = [];

if state.NFRAME == 41
   nframe = 40;
else    
   nframe = state.NFRAME;
end

for i = 1:nframe
    mat(i).XY = state.XY(:,:,i);
    mat(i).FRAME = i;
    mat(i).NOTE = [];
    mat(i).TRKRES = [];
    mat(i).TIME = [];
    mat(i).IMAGE = [];
    
    if i == 1
        mat(i).ANCHORS = state.ANCHORS;
    else
        mat(i).ANCHORS = [];
    end
end

eval(sprintf('%s = mat;', video_id));

% Save
save_file_dir = fullfile(save_dir, strcat(video_id,'.mat'));
save(save_file_dir, sprintf('%s',video_id));
fprintf('Saved in %s\n', save_file_dir);
