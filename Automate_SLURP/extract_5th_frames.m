function extract_5th_frames(mat_file, save_dir)
% This function will extract every 5th frames including the first frame
% and save the result under save_dir with the same name.
% 2018-12-02 Jaekoo

frames = [1,5,10,15,20,25,30,35,40];

[p,f,e] = fileparts(mat_file);
M = load(mat_file);
M = getfield(M, f);

NEW = struct('XY','','ANCHORS','','FRAME','','NOTE','','TRKRES','','TIME','','IMAGE','');

idx = 1;
for i = 1:length(M)
    for frame = frames
        if isequal(M(i).FRAME, frame)
            % Append
            NEW(idx).XY = M(i).XY;
            NEW(idx).ANCHORS = M(i).ANCHORS;
            NEW(idx).FRAME = M(i).FRAME;
            % Update idx
            idx = idx + 1;
        end
    end
end

% Save
eval(sprintf('%s=NEW;',f));
save(fullfile(save_dir, strcat(f,e)), sprintf('%s',f));
