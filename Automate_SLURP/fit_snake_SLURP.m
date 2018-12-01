function state = fit_snake_SLURP(state)
% This function uses 'Fit snake' method defined in SLURP
% 2018-11-30 Jaekoo

state.ANCHORS_VISIBLE = 0;

%Get Npoints
% hnpoints = findobj('tag', 'npoint');
% nPoints = get(hnpoints, 'String');
% state.XY = zeros(state.NPOINTS, 2, state.NFRAME);
% set(gcbf, 'userData');

%Get scale
% hnscale = findobj('tag', 'scale');
% scale = get(hnscale, 'string');
% state.SCALE = str2double(scale);
% set(gcbf, 'userData');

k = find(~ishandle(state.ALH));
state.ANCHORS(k,:) = [];
state.ALH(k) = [];
anchors = state.ANCHORS;
if size(anchors,1) < 4, return; end;
% set(gcbf,'pointer','watch'); drawnow;

% compute image external energy (based on gradient) here to
% save time
% Im = im2double(uint8(get(state.IH, 'cdata')));
Im = im2double(uint8(state.IH));
Egradient = Egrad(Im, 5.0, [1, 1, size(Im,2), size(Im,1)]);

% interpolate anchor points for initial snake approximation (use
% MATLAB's splines here rather than reprogram them in C)
arclength = [0; cumsum(sqrt(sum(diff(anchors).^2,2)))];
inc = arclength(end)/(state.NPOINTS-1);
init_pts = interp1(arclength, anchors, 0:inc:arclength(end), ...
    'spline');
arclength = [0; cumsum(sqrt(sum(diff(init_pts).^2,2)))];
state.LENGTHAVERAGE = arclength(end);
% set(gcbf, 'UserData',state);

[xy, state.START_ENERGY] = make_snake(Im', ...
    Egradient',...
    init_pts, state.OPT.Delta*ones(state.NPOINTS,1), ...
    state.OPT.BandPenalty, state.OPT.Alpha, state.OPT.Lambda1, 1);

% set(gcbf,'pointer','arrow');
state.XY(:,:,state.CURFRAME) = xy;
% set(state.CLH,'xdata',xy(:,1),'ydata',xy(:,2));
%set(state.ALH,'xdata',[],'ydata',[]);
state.ALH=[];
% set(gcbf,'userData',state);
disp('Fitted Snake')