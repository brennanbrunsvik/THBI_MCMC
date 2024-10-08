clc; clear; 
run('a0_parameters_setup.m'); % Set up all parameters and such in a0. Because there may be many scripts here dependent on those parameters. 
fpdfs = sprintf('%scompiled_pdfs_%s.mat',out_dir,STAMP); % File with pdfs. a2_1...m

mdls = load(fresults).mdls; 

%% parameters. 
rough_scale_base  = 1e-9; % How much to penalize roughness.
re_run = false; 

rough_scale_params = struct('zmoh', .0015*rough_scale_base,...
    'zsed', .1*rough_scale_base, 'xicr', .01*rough_scale_base); % Based on the max and min values in any parameter, determine how to change the roughness penalty. 

max_inv_iterations = 30; % How many iterations to allow in inversion. 

for version_surf = [7]; % Loop over different "versions" of models. Use 7. 
    
    disconts = {"xicr", "zsed", "zmoh"}; 
    
    to_invert = disconts; % Which model parameters to run. Those come first because they can influence later inversions.  
    % Merge to_invert with other model parameters
    if isempty(to_invert); warning('to_invert should start as == disconts'); end 
    for inum = int16([5:5:300]/5); % Which depths/incidices to run.
        to_invert{end+1} = inum; 
    end
    
    % Total hack to not worry as much about having depth slices of vs, but other things not being a function of depth. 
    for iinv = to_invert; %!%! Add strings to the list to handle other parameters. Make sure they are always first in list. 
        
        iinv = iinv{1}; 
        
        % Handle whether doing depth or other model parameter inversion
        v_at_depth = ~ strcmp(class(iinv), class("A string") ); % Use velocity from a depth, or one of the other parameters like moho depth. If a string is provided, we assume we are not using velocity at depth but another model parameter.
        if v_at_depth 
            param = z_vs(iinv); % Only do if v_at_depth. % 
            this_inversion = sprintf('vs%1.0f',param); % String name affiliated with figures and files.  
            rough_scale = rough_scale_base; % So we can modify rough_scale throughout. 
            fprintf('On inversion depth %1.0f\n', iinv)
        else
            param = iinv; 
            this_inversion = sprintf('%s',param); 
            rough_scale = rough_scale_params.(char(param)); 
            fprintf('On inversion %s\n', iinv)
        end
        
        mkdir(this_inversion); 
        
        fprintf('Running inversion %s\n', this_inversion)
        
        %% See if we already have results. 
        fname_surf_vals = sprintf('%s/surface_values_V%1.0f.mat', this_inversion, version_surf); 
        if exist(fname_surf_vals,'file') & (~re_run); 
            fprintf('Aleady have results for %s. Skipping. \n',this_inversion)
            continue; 
        end
        
        %% Reorganize structure. Could be more or less useful one way or other. 
        models = struct(); 
        zmoh          = zeros(length(mdls.nwk),1); 
        zmohsig       = zeros(length(mdls.nwk),1);
        zsed          = zeros(length(mdls.nwk),1);
        zsedsig       = zeros(length(mdls.nwk),1);
        xicr          = zeros(length(mdls.nwk),1); 
        vpvs          = zeros(length(mdls.nwk),1); 
        % vpvssig       = zeros(length(mdls.nwk),1);
        
        m_simple      = zeros(length(mdls.nwk), 1); 
        
        nsta = length(mdls.nwk); 
        for imd = 1:nsta; 
        
            % Make alternative format models variable. 
            models(imd).nwk   = mdls.nwk  {imd}; 
            models(imd).sta   = mdls.sta  {imd}; 
            models(imd).lat   = mdls.lat  (imd); 
            models(imd).lon   = mdls.lon  (imd); 
            models(imd).model = mdls.model{imd}; 
            models(imd).dir   = mdls.dir  {imd}; 
            
            % Extract map-view inversion results in cases where there's just one parameter for a station. 
            mdl = mdls.model{imd}; 
            zmoh              (imd) = mdl.zmohav; 
            zmohsig           (imd) = mdl.zmohsig; 
            zsed              (imd) = mdl.zsedav;     
            zsedsig           (imd) = mdl.zsedsig; 
            xicr              (imd) = mdl.xicrav;     
            vpvs              (imd) = mdl.vpvsav; 
        
            % Pseudo-tomography
            if v_at_depth
                [~,iclosest_z] = min( abs(z_vs(iinv) - mdl.Z) ); 
                m_simple(imd) = mdl.VSav(iclosest_z);
            else
                m_simple(imd) = mdl.(iinv+"av"); % This is better than doing the median later, since median didn't work for some model parameters. 
            end
            
        end
        
        %% Setting up coordinate system. 
        lonmin = min(mdls.lon-1); 
        latmin = min(mdls.lat-1); 
        lonmax = max(mdls.lon+1); 
        latmax = max(mdls.lat+1); 
        llminmax = [lonmin, lonmax, latmin, latmax]; % For easy passing to plotting functions
        
        figure(1); clf; hold on; 
        m_proj('lambert', 'long',[lonmin, lonmax],'lat',[latmin, latmax]);
        [stax, stay] = m_ll2xy(mdls.lon, mdls.lat);  % Get stax and stay!!!
        
        %% Plot stations positions. 
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay, ...
            'fignum', 1, 'title', 'station positions')
        
        %% Velocity or discontinuity? 
        if v_at_depth; 
            ivel = find(z_vs == param); 
            iz = ivel; 
        else
            iz = 'no different depths!'; 
        end
        
        %% Setting up surface. 
        nodes_per_degree = 4; 
        nx = ceil((lonmax - lonmin) * nodes_per_degree); 
        ny = ceil((latmax - latmin) * nodes_per_degree);  
        edge_space = 0.2; % How far to go beyond max and min stax and y, in fraction. 
        
        DX = max(stax) - min(stax); 
        DY = max(stay) - min(stay); 
        xline = linspace(min(stax) - edge_space * DX, max(stax) + edge_space * DX, nx)'; 
        yline = linspace(min(stay) - edge_space * DY, max(stay) + edge_space * DY, ny)'; 
        [xgrid, ygrid] = ndgrid(xline, yline);  
        [longrid, latgrid] = m_xy2ll(xgrid, ygrid); 
        
        m_interp = griddata(stax, stay, m_simple, xgrid, ygrid, 'cubic'); 
        
        %%% Plot surface. 
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay, 'stav', m_simple,... %!%! Replace vs(:,ivel)
            'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', m_interp, ...
            'fignum', 2, 'title', 'Simple v interpolation');  
        % scatter(xgrid, ygrid, 5, 'k', 'filled')
        
        exportgraphics(gcf, [this_inversion '/surface_simple_interpolation_V' num2str(version_surf) '.pdf']); 
        
        %% Get PDF for stations. 
        pdf_file = load(fpdfs); 
        pdfs = pdf_file.pdfs_allparm; 
        
        %%% Put this in function later. 
        if v_at_depth
            pdfs_vs = pdfs(1).vs{1}; % Make a new structure (obnoxious). And have to start with the correct field names. Reason for new structure is that, I used a cell array for each different depth. Matlab doesn't actually access the nth stations ith cell array all in one call. 
            nsta = length(pdfs); 
            for ista = 1:nsta
                pdfs_vs(ista) = pdfs(ista).vs{iz}; 
            end
            pdfs = pdfs_vs; 
        else
            iinvmod = iinv; 
            if strcmp(iinv, "xicr"); 
                iinvmod = iinv+"ust"; 
            end
            pdfs = [pdfs.(iinvmod)]; 
        end
        %%% Put this in function later. 
        
        %% Figure out how much to scale roughness based on heights of pdfs. 
        % This is just a way of addressing the
        % fact that all pdfs are normalized to 1, changing the balance of penalty
        % for pdf and penalty for roughness. 
        % Multiply penalty roughness by scale_sta_roughness. This is because a pdf
        % with wider model bounds will have smaller peaks and smaller max pdf. So
        % the biger the distribution, the smaller the max summed probability, and
        % the smaller our penalty should be. 
        bounds_ratio = [0.25, 0.75]; % Only worry about pdf within these cumulative pdf bounds. We have to pick some bounds where we think the model values are no longer relevant. 
        bounds_stas = zeros(nsta, length(bounds_ratio)); 
        for ista = 1:length(pdfs); 
            low_bound_scale = 0.25; 
            high_bound_scale = 0.75; 
            mm=pdfs(ista).mm; 
            pm=pdfs(ista).pm; 
            cpm = cumtrapz(mm, pm); 
            get_rid = (cpm > 0.99) | (cpm < 0.01); 
            mm = mm(~get_rid); 
            cpm = cpm(~get_rid);
            [C,IA,IC] = unique(cpm);  
            cpm = cpm(IA); % Sometimes there are duplicates for some probability. Then we can't interpolate this. Just remove them, this value doesn't have to be so precise. 
            mm  = mm (IA); 
            bounds_stas(ista,:) = interp1(cpm, mm, bounds_ratio, 'spline'); 
        end
        stas_mod_width = bounds_stas(:,2) - bounds_stas(:,1); 
        scale_sta_roughness = 1./stas_mod_width; 
        
        %% Make a starting model. 
        mgrid = m_interp; % Interpolated velocities are a fine starting model.
        mgrid(isnan(mgrid)) = nanmean(nanmean(mgrid)); 
        
        % Handle points outside station bounds. 
        for ipt = 1:(nx*ny)
            distpt = sqrt( (stax - xgrid(ipt)).^2 + (stay - ygrid(ipt)).^2 ); % distance of this point to each station
            distpt = distpt ./ (sqrt(DX.^2 + DY.^2)); 
            [distpts, distpti] = sort(distpt); 
            exponent = 4; 
            max_ind = size(m_simple, 1); 
            distpts = distpts(1:max_ind);
            vspt = m_simple( distpti(1:max_ind) );
            sta_wt = (1./distpts).^exponent; 
            sta_wt = sta_wt / sum(sta_wt); 
            v_new = sum(sta_wt .* vspt); 
            mgrid(ipt) = v_new;  
        end
        
        % Plot the starting model. 
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay, 'stav', m_simple,... 
            'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', mgrid, ...
            'fignum', 3, 'title', 'V starting model'); 
        exportgraphics(gcf, [this_inversion '/surface_starting_model_V' num2str(version_surf) '.pdf']); 
        
        %% Set up grid roughness calculations. Use 2nd derivative smoothing. 
        dx2 = ((xgrid(1:end-2,:) - xgrid(3:end,:))/2).^2; % Squared, so sign doesn't matter. 
        dy2 = ((ygrid(:,1:end-2) - ygrid(:,3:end))/2).^2; 
        x_dx2 = xgrid(2:end-1,:); y_dx2 = ygrid(2:end-1,:); % x and y positions where we have dx. I think just for plotting. 
        y_dy2 = ygrid(:,2:end-1); x_dy2 = xgrid(:,2:end-1); % y and x positions where we have dy
        
        %% Example roughness to make sure the calculations are good. 
        % This is the calculation to get roughness throughout the inversion (Basically). 
        dvdx2 = (mgrid(1:end-2,:) - 2*mgrid(2:end-1,:) + mgrid(3:end,:))./dx2; 
        dvdy2 = (mgrid(:,1:end-2) - 2*mgrid(1,2:end-1) + mgrid(:,3:end))./dy2; 
        dvdx2 = dvdx2.^2; % Square, mostly to prevent negative values...
        dvdy2 = dvdy2.^2; 
        roughness = sum(dvdx2, 'all') + sum(dvdy2, 'all'); % replace dvdx2 and dvdy2
        roughness = roughness * rough_scale; % How to get roughness penalty value. 
        
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay,...
            'xgrid', x_dx2, 'ygrid', y_dx2, 'vgrid', dvdx2, ...%Replace dvdx2 and dvdy2
            'fignum', 4, 'title', 'X roughness'); colorbar(); 
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay,...
            'xgrid', x_dy2, 'ygrid', y_dy2, 'vgrid', dvdy2, ...%Replace dvdx2 and dvdy2
            'fignum', 5, 'title', 'Y roughness'); colorbar(); 
        
        mgrid_start = mgrid; 
        
        %% Prep for efficient inverison. Some constant variables. 
        
        % Interpolate each pdf to common mm grid. 
        % Important for computational efficient when calculating penalty. 
        nsta = length(pdfs); 
        nmm = 300; 
        [pdf_terp, mm_terp, dmm_di] = p_prep_mm_to_pdf(pdfs, nmm); 
        
        % Interpolate mm from the grid to stations.  
        [fhand_vec_nouse, fhand_mat_nouse, grid_terp, nearesti, weighti...
            ] = p_prep_grid_to_sta_interp(...
            xgrid, ygrid, mgrid, stax, stay); 
        
        %% Modify roughness and grid interpolation. 
        % Don't apply smoothing across discontinuities, e.g. if at 35 km we transition from crust to mantle, then the velocity smoothing should not occur across that transition. 
        % Don't interpolate at a station if it's on a discontinuity. 
        if (v_at_depth) & (version_surf ~= 3); % Version 3 had a different format. This shouldn't matter now, since we are doing new versions. 
            for this_surf = disconts;
                this_surf = this_surf{1}; 
                zdisc = load(sprintf('%s/surface_values_V%1.0f', this_surf, version_surf)).mgrid_out; 
                gthan = zdisc > param; % Depth greater than this discontinuity. Where we switch from 1 to 0, there is a discontinuity. 
        
                % Handle smoothing. X and Y comparison. Where xcomp and ycomp are true, there is no smoothing across discontinuities.  
                xcomp = (gthan(2:end-1,:) == gthan(3:end,:)) &...
                    (gthan(2:end-1,:) == gthan(1:end-2,:)); 
                ycomp = (gthan(:,2:end-1) == gthan(:,3:end)) &...
                    (gthan(:,2:end-1) == gthan(:,1:end-2)); 
                pct_rem = @(pcomp)100 * sum(pcomp == 0, 'all') / numel(pcomp); 
                fprintf('Removing smoothing from %1.5f%% x and %1.5f%% y cells, %s\n', ...
                    pct_rem(xcomp), pct_rem(ycomp),  this_surf)
                
                dx2(~xcomp) = inf; % Sort of a hack. Set dx and dy to inf where we don't care to smooth. Because the derivative at those spots will be change in value over inf, which is 0.  
                dy2(~ycomp) = inf; 
                
                % Handle station interpolation
                stas_removed = []; 
                for ista = 1:nsta; 
                    if length(unique(gthan(nearesti(ista,:)))) > 1; % This station is in a discontinuity
                        weighti(ista,:) = 0; % Set 0 weight for interpolation of this station. PDF is always 0. Can't affect inversion. 
                        grid_terp(:,ista) = 0; % Same as above. 
                        stas_removed = [stas_removed; ista]; 
                    end
                end
                fprintf('Removing %1.0f stations from interpolation due to %s intersection.\n', ...
                    length(stas_removed), this_surf); 
            end
        else
            stas_removed = []; % Keeping all stas. 
        end
        
        stas_kept = true(nsta,1); 
        stas_kept(stas_removed) = false; 
        
        % Re-calculate how much we should multiply roughness penalty to handle
        % wider/narrower pdf bounds... now that we know which stations to use. 
        mult_roughness = mean(scale_sta_roughness(stas_kept)); % Excluding these stations probably doesn't make much of a difference. 
        rough_scale = rough_scale * mult_roughness; 
        
        %% Penalty. Make a function handle with one argument for what we want to minimze. 
        fhand_penalty=@(mgrid)a3_1_penalty_efficient(mgrid,...
            pdf_terp, rough_scale, dx2, dy2, xgrid, ygrid, stax, stay, ...
            nearesti, weighti, min(mm_terp), dmm_di, nmm, nsta); 
        
        % For comparison, what is the max pdf sum that could ever be achieved? 
        pdf_total_max = sum(max(pdf_terp,[],1)); 
        
        %% Test the above efficient inversion interpolation stuff. 
        msta_mod = linspace(min(mm_terp), max(mm_terp), nsta)'; % FOR TESTING Easy values, for testing.
        pdf_mod = p_mm_to_pdf_dmdi(...
            msta_mod, pdf_terp, min(mm_terp), dmm_di, nmm, nsta); %!%! replace vsta_mod
        
        % Plot to check that we interpolated to a common mm correctly. 
        figure(12); clf; hold on; 
        set(gcf, 'color', 'white')
        tiledlayout(2,1,'TileSpacing','compact'); 
        nexttile(); hold on; box on; set(gca, 'LineWidth', 1.5); 
        title('Interpolated') 
        for ista = 1:nsta
            plot(ista  + pdf_terp(:,ista), mm_terp ); 
        end
        scatter([1:nsta]' + pdf_mod, msta_mod); 
        
        nexttile(); hold on; box on; set(gca, 'LineWidth', 1.5); 
        title('Original'); 
        for ista = 1:nsta; 
            plot(ista + pdfs(ista).pm, pdfs(ista).mm)
        end
        
        %% Example of running the inversion. 
        options = optimoptions("fminunc",Display="iter",...
            MaxFunctionEvaluations=inf,MaxIterations=max_inv_iterations,...
            Algorithm='quasi-newton');
        
        opts = options;
        opts.Algorithm = 'quasi-newton';
        opts.HessianApproximation = 'lbfgs';
        opts.SpecifyObjectiveGradient = false;
        
        fprintf('Sum of max of pdf of each station: %1.1f.\nExcluding roughness, this is best possible penalty.\n', sum(max(pdf_terp)) )
        
        %% Iterate and see how model changes
        tic; 
        ii = 0; 
        mgrid_temp = mgrid_start; 
        opts_temp = opts; 
        ii_vec = [0]; 
        [pentot_ii,penpdf_ii,penprior_ii, pennorm_ii] = fhand_penalty(mgrid_temp); 
        opts_temp.MaxIterations = 0; 
        while ii < max_inv_iterations; 
        
            % How many iterations to do? Not efficient to start inversion too many times.     
            if ii < 5; 
                opts_temp.MaxIterations = 1; 
            elseif ii < 15; 
                opts_temp.MaxIterations = 2; 
            elseif ii < 50; 
                opts_temp.MaxIterations = 6; 
            elseif ii < 300; 
                opts_temp.MaxIterations = 15; 
            end
        
            if ii + opts_temp.MaxIterations > max_inv_iterations; 
                opts_temp.MaxIterations = min([1, max_inv_iterations - opts_temp.MaxIterations])
            end
        
            [mgrid_temp,fval_out,flag_out,output_out] =...
                fminunc(fhand_penalty, mgrid_temp, opts_temp);
        
            ii = ii + output_out.iterations; 
            ii_vec(end+1) = ii; 
            [pentot_ii(end+1),penpdf_ii(end+1),penprior_ii(end+1), pennorm_ii(end+1)...
                ] = fhand_penalty(mgrid_temp); 
        
        end
        mgrid_out = mgrid_temp; 
        toc
        
        %% Plot how inversion progressed
        for yscale_type = ["log", "linear"]; 
            figure(13); clf; hold on; 
            box on; set(gca, 'LineWidth', 1.5); 
            
            title(sprintf('Surface inversion progress. Max possible: %1.1f', pdf_total_max),...
                'FontWeight','normal'); 
            yyaxis('left'); 
            ylabel('\Sigma P(m)')
            set(gca, 'YScale', yscale_type, 'YDir', 'reverse')
            grid on; 
            
            plot(ii_vec, - penpdf_ii); 
            scatter(ii_vec, - penpdf_ii, 'filled');  
                
            yyaxis('right'); 
            ylabel('Roughness'); 
            plot(ii_vec, penprior_ii); 
            scatter(ii_vec, penprior_ii, 'filled'); 
            set(gca, 'YScale', yscale_type)
            xlabel('Iteration'); 
            grid on; 
            
            exportgraphics(gcf, sprintf('%s/surface_inversion_progress_%s_%1.0f.pdf',...
                this_inversion, yscale_type, version_surf)); 
        end
        
        %% Percent changes throughout inversion, per ii
        fhand_prog = @(invval)(diff(invval) ./ diff(ii_vec))' ./ max(invval) * 100; 
        [ii_vec(2:end)', fhand_prog(pentot_ii), fhand_prog(penpdf_ii), fhand_prog(penprior_ii)]
        
        %% Plot inversion output. 
        a3_2_plot_surface_simple(llminmax, 'stax', stax, 'stay', stay, 'stav', m_simple,... 
            'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', mgrid_out, ... 
            'fignum', 6, 'title', 'V output'); 
        exportgraphics(gcf, sprintf('%s/surface_inversion_rough_V%1.0f.pdf',...
            this_inversion, version_surf)); 
        
        % Temporary. Mostly for testing. 
        save('surface_out_example.mat', 'longrid', 'latgrid',...
            'xgrid', 'ygrid', 'llminmax'); % Longrid and stuff isn't going to change. 
        save(fname_surf_vals, 'mgrid_out')
    
    end
end 