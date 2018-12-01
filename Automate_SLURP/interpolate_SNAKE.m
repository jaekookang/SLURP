function state = interpolate_SNAKE(state, Npoints)
% Interpolate points from snake w/ particle filtering to the desired points
% 2018-11-30 Jaekoo
%
% **NOTE
% - SLURP tracks only N-1 frames (BUG). To prevent this, (N-1)th frame is
%   copied to Nth frame. This has to be improved.

%     main_fig=get(gcbf, 'UserData');
%     hnpoints = findobj('tag', 'Npoints');
%     Npoints = str2double(get(hnpoints, 'String'));
%     close(gcbf);
%     state = get(main_fig,'userData');
XYnew = zeros(Npoints, 2, state.NFRAME);
%             for f = 1:state.NFRAME
if state.NFRAME == 41
   frame = 40; 
   fprintf('NFRAME is adjusted to %d for interpolation\n', frame); % jaekoo 2018-11-30
elseif state.NFRAME == 40
   frame = state.NFRAME;
   % Duplicate the 39th frame to 40th frame because 39th frame is zeros (BUG).
   state.XY(:,:,end) = state.XY(:,:,end-1);
else
   error('Frame is not either 40 or 41; It is %d\n',state.NFRAME);
end

for f = 1:frame % up to 40 frames (not 41 frames), jaekoo 2018-11-30
    state.CURFRAME = f;
    arclength = [0; cumsum(sqrt(sum(diff(state.XY(:,:,state.CURFRAME)).^2,2)))];
    inc = arclength(end)/(Npoints-1);
    xy = state.XY(:,:,state.CURFRAME);
    XYnew(:,:,f) = interp1(arclength, xy...
        , 0:inc:arclength(end), 'spline');
    state.IH = uint8(mean(read(state.MH,f),3));
    state.TH = sprintf('%04d',f);
    state.CLH.xdata = XYnew(:,1,f);
    state.CLH.ydata = XYnew(:,2,f);
    %         set(state.IH,'cdata',uint8(mean(read(state.MH,f),3)));
    %         set(state.TH,'string',sprintf('%04d',f));
    %         set(state.CLH,'xdata',XYnew(:,1,f),...
    %             'ydata',XYnew(:,2,f));
end
state.XY = XYnew;
state.NPOINTS = Npoints;
%     set(main_fig,'userData',state);


end