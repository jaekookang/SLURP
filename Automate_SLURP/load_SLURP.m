function state = load_SLURP(video_file, seed_file, slurp_dir)
% This function initialize video file with a seed file
% 2018-11-30 Jaekoo

[f,p,e] = fileparts(video_file);
p = strcat(p, e); % eg., video.avi

% defaults
anchors = [];
nPointsDef = 39;
% nPointsDef = 100;
scaleDef = 98/321;
vName = '';
opt = struct('Sigma', 5.0, 'Delta', 2, 'BandPenalty', 2.0, ...
    'Alpha', 0.8, 'Lambda1', 0.95, 'MinParticles', ...
    10, 'MaxParticles', 1000, 'Nparticles', -1);


% look for default shape and motion models.
model = [];
default_shape_filename = fullfile(slurp_dir,'ShapeModel.mat');
default_motion_filename = fullfile(slurp_dir,'MotionModel.mat');
if exist(default_shape_filename) == 2 && ...
        exist(default_motion_filename) ==2
    load(default_shape_filename);
    load(default_motion_filename);
    
    if exist('ShapeData') && exist('motion_model_var')
        model = struct('Evectors', ShapeData.Evectors,...
            'Evalues', ShapeData.Evalues,...
            'x_mean', ShapeData.x_mean,...
            'motion_cov', kron(motion_model_var, ...
            motion_model_var').*motion_model_corr_coef);
        disp('Default shape and motion models loaded');
    end
end

%% (1) Load a video file
if ~(isequal(p,0) || isequal(f,0))
    fName = fullfile(f,p);
    [pathn, fn, en] = fileparts(fName);
    try,
        mh = VideoReader(fName);
    catch,
        error('unable to open %s', fName);
    end;
    try,
        
        frame = 1;
        img = read(mh,frame);
        nFrames = get(mh,'numberOfFrames');
        for ii = 1:min(nFrames,200)
            img_data(:,:,ii) = double(rgb2gray(read(mh,ii)));
        end
        
        % find image mask by looking at parts where there is variation from one
        % image to the next (the background should be 99% the same between all
        % images since they come from the same machine
        var_img = var(img_data, 0, 3);
        mask = var_img > 2;
        
        
        CC = bwconncomp(mask);
        numOfPixels = cellfun(@numel,CC.PixelIdxList);
        [unused,indexOfMax] = max(numOfPixels);
        unmask = zeros(size(mask));
        unmask(CC.PixelIdxList{indexOfMax}) = 1;
        
        mask = unmask;
        
    catch,
        error('unable to load frame %d in %s', frame, fName);
    end;
    
    
    %     % display image
        img = uint8(mean(img,3));
    %     ih = imshow(img);
    %     th = text(50,80,sprintf('%04d',frame),'fontsize',18,'color','w');
    %
    %     % create emit array
    %     if ~isempty(vName),
    %         uimenu(menu,'label','Emit Contour','separator','on','accelerator','E','callback',{@SLURP,'EMIT',1});
    %         assignin('base',vName,NaN(nPointsDef,2,nFrames,'single'));
    %         fprintf('created %s [%d contour points x X,Y x %d movie frames] in base ws\n',vName,nPointsDef,nFrames);
    %     end;
    
    
    
    
    % init parameters for frames correction
    param_correc = struct('FBEF', 0,...
        'FAFT', 0,...
        'TRESHENER', 0,...
        'AUTO', true);
    
    % init parameters for reverse tracking
    param_tracking = struct('FBEF', 0,...
        'FAFT', 0);
    
    % init internal state
    state = struct('IH', img, ...				% image handle
        'MH', mh, ...				% movie handle
        'TH', [], ...				% text handle
        'TARGFRAME', frame, ...		% target frame
        'CURFRAME', frame, ...		% currently displayed frame
        'NFRAME', nFrames, ...		% number of available frames
        'MASK', mask, ...
        'RH', [], ...				% contrast adjustment handle
        'NPOINTS', nPointsDef, ...		% number of contour points
        'ANCHORS', anchors, ...		% current anchor points
        'ALH', [], ... % and their line handles
        'ANCHORS_VISIBLE', 1,...
        'XY', [], ... % current contour points
        'CLH', [], ...  % and their line handle
        'FWD', [],...
        'FWD_CLH', [],...
        'BWD', [],...
        'BWD_CLH',[],...
        'OLDANCHORS', [],...        % contour points before correction
        'SCALE', scaleDef,...          % Image scale
        'VNAME', vName,...          % emit array name
        'CORREC', true,...          % if false, "Corrected frames" has been called
        'ENERGY', [],...
        'START_ENERGY', [], ...
        'LENGTHAVERAGE', 1, ...    % Length of the first snake
        'PTS_ANCRAGE', [0 0],...   % Corrected points
        'CORRECTED', true,...      % if true, "3 corrected points has been chosen
        'PARAM_CORREC', param_correc,...
        'PARAM_TRACK' , param_tracking, ...
        'USER_TIME', 0, ...
        'OPT', opt,...
        'MODEL', model,...
        'VIDEO_NAME', [pathn,'/',fn]);
    
    
    state.XY = zeros(state.NPOINTS, 2, state.NFRAME);
    
    
    % Slide to choose the reference frame
    %     position = get(currentFigure, 'Position');
    %     width = position(3);
    maxframe = state.NFRAME;
    %     hSlider = uicontrol('Style', 'slider',...
    %         'userData', currentFigure,...
    %         'Max', maxframe, ...
    %         'Min', 1, ...
    %         'SliderStep', [1 1]/(maxframe-1), ...
    %         'Value', state.CURFRAME,...
    %         'Position', [5 5 width/2 20],...
    %         'Callback', @slider_targframe);
    
    % Edit with the number of point
    %     uicontrol('Style', 'text', ...
    %         'String', 'Npoint', ...
    %         'Position',  [width/2+20 25 50 20])
    %     hnpoint = uicontrol('Style', 'edit',...
    %         'Value', nPointsDef,...
    %         'tag', 'npoint', ...
    %         'String', num2str(nPointsDef),...
    %         'Position', [width/2+20 5 50 20]);
    
    % Edit with the scale
    %     uicontrol('Style', 'text', ...
    %         'String', 'Scale', ...
    %         'Position',  [width/2+100 25 50 20])
    %     hnscale = uicontrol('Style', 'edit',...
    %         'Value', scaleDef,...
    %         'tag', 'scale', ...
    %         'String', num2str(scaleDef),...
    %         'Position', [width/2+100 5 50 20]);
    %
    %     set(currentFigure,'name',sprintf('%s  frame %03d',f,frame), ...
    %         'busyAction','cancel', ...
    %         'closeRequestFcn',{@SLURP,'CLOSE'}, ...
    %         'tag','SLURP', ...
    %         'userData',state);
    %     set(ih,'buttonDownFcn', {@SLURP,'DOWN'});
    
    
    % initialize contour from passed-in anchor points
    if ~isempty(anchors),
        for k = 1 : size(anchors,1),
            state.ALH(k) = line(anchors(k,1),anchors(k,2),'marker','.','color','r','tag','CONTOUR','buttonDownFcn',{@SLURP,'DOWN','POINT'});
        end;
        %         set(currentFigure,'userData',UpdateContour(state));
    end;
    if isunix, [s,r] = unix('osascript -e ''tell application "MATLAB" to activate'''); end;
    
    %% (2) Load a seed
    [p,f,e] = fileparts(seed_file);
    filename = strcat(f, e);
    pathname = p;
    if ~(isequal(filename,0) || isequal(pathname,0))
        load(fullfile(pathname, filename))
        state.CURFRAME = initialization.frame;
%         set(state.IH,'cdata',uint8(mean(read(state.MH,state.CURFRAME),3)));
%         set(state.TH,'string',sprintf('%04d',state.CURFRAME));
        state.ANCHORS =  initialization.anchors;
%         for k = 1 : length(initialization.anchors),
%             state.ALH(k) = line(initialization.anchors(k,1),initialization.anchors(k,2),...
%                 'marker','.','color','r','tag','CONTOUR','buttonDownFcn',{@SLURP,'DOWN','POINT'});
%         end;
        state.ANCHORS_VISIBLE = 1;
%         set(gcbf,'userData',UpdateContour(state));
        
    end 
end

