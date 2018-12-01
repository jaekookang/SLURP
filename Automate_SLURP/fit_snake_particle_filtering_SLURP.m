function state = fit_snake_particle_filtering_SLURP(state)
% This function fits snake with particle filtering on subsequent frames
% based on the seed frame given.
% 2018-11-30 Jaekoo

% state = get(gcbf,'userData');

if isempty(state.MODEL)
    errordlg(['No shape and motion models loaded.  Please load ' ...
        'suitable shape and motion models before using the ' ...
        'particle filter, or use tracking without particle ' ...
        'filtering.']);
else
    
    frameInc = 1;
    endFrame = state.NFRAME-1;
    
    s = RandStream('mcg16807','Seed',0);
    RandStream.setGlobalStream(s);
    state.ANCHORS_VISIBLE = 0;
    
    energy = zeros(state.NPOINTS, state.NFRAME);
    energy(:,state.CURFRAME) = state.START_ENERGY;
    
    Evectors = state.MODEL.Evectors;
    Evalues = state.MODEL.Evalues;
    x_mean = state.MODEL.x_mean;
    motion_cov = state.MODEL.motion_cov;
    
    % start is the reference frame
    start = state.CURFRAME;
    % The reference frame's snake is used for the next frame
    xy = state.XY(:,:,state.CURFRAME);
    start_length = sum(sqrt(sum(diff(xy).^2,2)));
    
    
    
    % get state vector for initial frame
    for frameInc = -1:2:1
        if state.OPT.Nparticles < 0
            max_particles = state.OPT.MaxParticles;
        else
            max_particles = state.OPT.Nparticles;
        end
        min_particles = state.OPT.MinParticles;
        Nparticles = max_particles;
        pfstate = zeros(3+size(Evectors,2),Nparticles);
        if frameInc < 0
            endFrame = 1;
        else
            endFrame = state.NFRAME-1;
        end
        xy = state.XY(:,:,start);
        pfstate(1:2,:) = repmat(xy(1,:)',1,Nparticles);
        normalized_pts = reshape((xy - repmat(pfstate(1:2,1)',length(xy),1)),[],1)./ ...
            start_length;
        pfstate(3,:) = ones(1,Nparticles); % length scale wrt original
        % tongue length
        
        pfstate(4:end,:) = repmat(((normalized_pts - x_mean)'*Evectors)',1,Nparticles);
        
        % get asm contour from projected particle states
        for pp=1:Nparticles
            pt_vec = (x_mean + sum(repmat(pfstate(4:end,pp)', ...
                length(Evectors),1).*Evectors,2));
            pf_xy(:,:,pp) = reshape(pt_vec, length(xy), 2);
            pf_xy(:,:,pp) = pf_xy(:,:,pp).* pfstate(3,pp).*start_length + ...
                repmat(pfstate(1:2,pp)',length(xy),1);
        end
        
        for f = start+frameInc:frameInc:endFrame
%             set(state.IH,'cdata',uint8(mean(read(state.MH,f),3)));
            state.IH = uint8(mean(read(state.MH,f),3));
            set(state.TH,'string',sprintf('%04d',f));
            state.CURFRAME = f;
            set(state.CLH,'xdata',state.XY(:,1,f-frameInc),...
                'ydata',state.XY(:,2,f-frameInc));
            
            % sample new particles using state transition model
            % for the moment, assume uncorrelated gaussian noise for
            % the 5 variables
            old_state = pfstate;
            
            rv = mvnrnd(zeros(1,size(pfstate,1)), motion_cov, ...
                max_particles);
            
            pfstate(1:2,:) = pfstate(1:2,:) + start_length* ...
                repmat(pfstate(3,:),[2 1]).*...
                rv(:,1:2)';
            
            pfstate(3:end,:) = pfstate(3:end,:) + rv(:,3:end)';
            
            % evaluate new particles using external energy terms in
            % snake model
            % pre-compute image gradient
%             Im = im2double(uint8(get(state.IH,'cdata')));
            Im = im2double(uint8(state.IH));
            Egradient = Egrad(Im, 5.0, [1, 1, size(Im,2), size(Im,1)], state.MASK);
            
            ImTrans = Im';
            EgradientTrans = Egradient';
            
            pf_xy = zeros(length(xy), 2, max_particles);
            pxy = zeros(size(pf_xy));
            p_energy = zeros(length(xy),max_particles);
            
            pp = 0;
            cumlike = 0;
            minlike = 7*exp(-sum(state.START_ENERGY));
            like_thresh = minlike;
            
            while (pp < max_particles-1 && (cumlike < like_thresh || ...
                    state.OPT.Nparticles > 0)) || pp < min_particles-1
                pp  = pp + 1;
                
                % get snaxel positions from particle state vector
                pt_vec = (x_mean + sum(repmat(pfstate(4:end,pp)',length(Evectors),1).*Evectors,2));
                pf_xy(:,:,pp) = reshape(pt_vec, length(xy), 2);
                pf_xy(:,:,pp) = pf_xy(:,:,pp).* pfstate(3,pp).*start_length + ...
                    repmat(pfstate(1:2,pp)',length(xy),1);
                
                [pxy(:,:,pp), p_energy(:,pp)] = ...
                    make_snake(ImTrans, ...
                    EgradientTrans, ...
                    pf_xy(:,:,pp), state.OPT.Delta*ones(state.NPOINTS,1), ...
                    state.OPT.BandPenalty, state.OPT.Alpha, state.OPT.Lambda1, 0);
                
                Eext(pp) = sum(p_energy(:,pp));
                
                len = sum(sqrt(sum(diff(pxy(:,:,pp)).^2,2)));
                lratio(pp) = max(len/start_length, start_length/len);
                %lratio(pp) = 1;
                
                cumlike = cumlike + exp(-Eext(pp)*lratio(pp));
            end
            Nparticles = pp + 1;
            
            % compute particle weights from external energy
            like(1:Nparticles-1) = exp(-Eext(1:Nparticles-1).*lratio(1:Nparticles-1));
            
            % show curve corresponding to most likely particle
            [max_w(f), index] = max(like(1:Nparticles-1));
            
            % get snaxel positions from processed particle state vector
            xy = pxy(:,:,index);
            [xy, energy(:,f)] = ...
                make_snake(ImTrans, ...
                EgradientTrans, xy, state.OPT.Delta*ones(state.NPOINTS,1), ...
                state.OPT.BandPenalty, state.OPT.Alpha, state.OPT.Lambda1, 1);
            
            
            len = sum(sqrt(sum(diff(xy).^2,2)));
            lr = max(len/start_length, start_length/len);
            
            % save updated best state to new particle
            pfstate(:,Nparticles) = zeros(size(pfstate,1),1);
            pfstate(1:2,Nparticles) = xy(1,:);
            pfstate(3,Nparticles) = sum(sqrt(sum(diff(xy).^2,2)))./start_length;
            normalized_pt = reshape((xy(:,:)-...
                repmat(pfstate(1:2,Nparticles)',length(xy(:,:)),1)),...
                [],1)./(pfstate(3,Nparticles)*start_length);
            pfstate(4:end,Nparticles) = (normalized_pt - x_mean)'*Evectors;
            
            saved_state(:,f-frameInc) = pfstate(:,Nparticles);
            
            % get asm contour from projected particle state
            best_pt_vec = (x_mean + sum(repmat(pfstate(4:end,Nparticles)', ...
                length(Evectors),1).*Evectors,2));
            best_pf_xy = reshape(best_pt_vec, length(xy(:,:)), 2);
            best_pf_xy = best_pf_xy.* pfstate(3, Nparticles).*start_length + ...
                repmat(pfstate(1:2,Nparticles)',length(xy),1);
            
            
            state.XY(:,:,f) = xy;
            set(state.CLH,'xdata',state.XY(:,1,f),'ydata',state.XY(:,2, ...
                f));
%             set(gcbf,'pointer','watch'); drawnow;
%             set(gcbf,'userData',state);
            like(Nparticles) = exp(-sum(energy(:,f)*lr));
            weight = like(1:Nparticles)./sum(like(1:Nparticles));
            
            cdf = cumsum(weight);
            cdf_prev = circshift(cdf,[0 1]);
            cdf_prev(1) = 0.0;
            samples = rand(max_particles,1);
            for pp = 1:max_particles
                try,
                    ix(pp) = find(cdf >= samples(pp) & cdf_prev <= ...
                        samples(pp));
                catch,
                    samples(pp)
                    cdf
                    pause;
                end;
            end
            
            new_pfstate = zeros(size(pfstate,1),max_particles);
            new_pfstate = pfstate(:,ix(1:max_particles));
            
            pfstate = new_pfstate;
            
        end
    end
    
%     fig =  figure('name', 'energy');
    %Normalize energy
    for i=1:state.NFRAME
        energy_visu(1:state.NPOINTS-1,i) = 100*((energy(1: ...
            state.NPOINTS-1,i)-energy(1:state.NPOINTS-1,start))./energy(1:state.NPOINTS-1,start));
        energy_visu = energy_visu .* (energy_visu >= 0);
    end
    
    state.RAW_ENERGY = energy;
    state.ENERGY(:,:)= energy_visu(:,:);
    state.ENERGY(state.NPOINTS,:)= energy_visu(state.NPOINTS-1,:);
    
    % Save the reference energy at the end of the array
    state.ENERGY(:,state.NFRAME+1) = energy(:,start);
    
%     set(gcbf,'userData',state);
    % Display energy map
%     imagesc(energy_visu(1:state.NPOINTS-1,1:state.NFRAME), [0 400]);
%     colormap('gray');
%     xlabel('frame no.');
%     ylabel('snaxel no.');
    
    % Attached main figure to energy map's axes.
%     setappdata(gca,'fig',gcbf);
%     dcmObj = datacursormode(fig);
    %Modify  UpdateFcn of the cursor (When an user click on the map)
%     set(dcmObj,'UpdateFcn',@myupdatefcn,'Enable','on');
    fprintf('Fitted Snake with particle filtering for %d frames\n', state.NFRAME);
end
