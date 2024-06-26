clc; clear; 
run('a0_parameters_setup.m'); % !!! Set up all parameters and such in a0. Because there may be many scripts here dependent on those parameters. 
fpdfs = sprintf('%scompiled_pdfs_%s.mat',out_dir,STAMP); % File with pdfs. a2_1...m
f_xsect_positions = './xsect_positions.mat'; % For loading cross-section positions

version_surf = 7; 
n_surf_pts = 100; 

convert_deg_km = 2*pi*6371/360; % Number to convert degrees to kilometers

% Cross section stuff, copy to cross-section code. initially from b1_plot_xsects_paper1.m
version_surf = 7; 
ll_min_max_map = [-89  -72   32   46]; % Map view
xsect_positions = load(f_xsect_positions); 
lolim = xsect_positions.lolim; 
lalim = xsect_positions.lalim; 

%
fnum = 101; 
scale_pdf = 0.1; 
offsecmax = 1.5; %5%  distance off section allowed, in degrees

% disconts = {"zsed", "zmoh"}; 
disconts = {"zmoh"}; 

to_invert = disconts; % Which model parameters to run. Those come first because they can influence later inversions.  
if isempty(to_invert); warning('to_invert should start as == disconts'); end 
for inum = int16([]/5); % Which depths/incidices to run. 
    to_invert{end+1} = inum; 
end

for iinv = to_invert; %!%! Add strings to the list to handle other parameters. Make sure they are always first in list. 
    iinv = iinv{1}; 
    
    % Handle whether doing depth or other model parameter inversion
    v_at_depth = ~ strcmp(class(iinv), class("A string") ); % Use velocity from a depth, or one of the other parameters like moho depth. If a string is provided, we assume we are not using velocity at depth but another model parameter. %!%! Utilize v_at_depth
    if v_at_depth 
        param = z_vs(iinv); %!%! Only do if v_at_depth. %!%! change variable depth. 
        depth = param; 
        iz = find(z_vs == depth); 
        this_inversion = sprintf('vs%1.0f',param); % String name affiliated with figures and files. %!%! change variable depth. 
    else
        param = iinv; 
        this_inversion = sprintf('%s',param); 
    end
    
    mdls = load(fresults).mdls; 
    sfsmat = load('surface_out_example.mat'); xgrid = sfsmat.xgrid; ygrid = sfsmat.ygrid; llminmax = sfsmat.llminmax; latgrid = sfsmat.latgrid; longrid = sfsmat.longrid; 
    sfsmat2= load(sprintf('%s/surface_values_V%1.0f', this_inversion, version_surf)); vgrid_out = sfsmat2.mgrid_out; 
    
    pdf_file = load(fpdfs); 
    pdfs = pdf_file.pdfs_allparm; 
    if v_at_depth
        pdfs_vs = pdfs(1).vs{1}; % Make a new structure (obnoxious). And have to start with the correct field names. Reason for new structure is that, I used a cell array for each different depth. Matlab doesn't actually access the nth stations ith cell array all in one call. 
        nsta = length(pdfs); 
        for ista = 1:nsta
            pdfs_vs(ista) = pdfs(ista).vs{iz}; %!%! Not access pdfs.vs
        end
        pdfs = pdfs_vs; %!%! replace pdfs_vs. 
    else
        pdfs = [pdfs.(iinv)]; 
    end
    
    %% Prep pdf-section style figure
    figure(fnum); clf; hold on; 
    set(gcf, 'pos', [1053 564 767 329*size(lolim,1)])
    tiledlayout(size(lolim, 1 ), 1,'TileSpacing', 'Compact')
    
    %% Get station data and plot it. Loop over different x sections. 
    lat_surf_line_all = zeros(n_surf_pts, size(lolim,1) ); 
    lon_surf_line_all = lat_surf_line_all; 
    all_ms = []; 
    all_pms = []; 
    all_cpms = []; 
    for i_xsect = size(lolim, 1):-1:1; 
        Q1 = [lalim(i_xsect, 1), lolim(i_xsect, 1)];
        Q2 = [lalim(i_xsect, 2), lolim(i_xsect, 2)]; 
        [profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
        
        by_line = logical(zeros(size(mdls.lon))); 
        d_perp  = zeros(        size(mdls.lon)) ; 
        d_par   = zeros(        size(mdls.lon)) ; 
        d_lon   = zeros(        size(mdls.lon)) ; 
        for ista = 1:length(mdls.lon); 
            [d_perp(ista),d_par(ista)] = dist2line_geog( Q1,Q2,...
                [mdls.lat(ista),mdls.lon(ista)],0.0025 );   
            d_lon(ista) = mdls.lon(ista); 
        
            if d_perp(ista) <= offsecmax; 
                by_line(ista) = true; 
            end
        end
        
        %%
        section_letter = char(64+i_xsect); % Text for cross-section name. ith letter of alphabet
        figure(fnum); 
        nexttile(); hold on; 
        set(gca, 'LineWidth', 1.5); 
        xlabel('Distance along section (degree)'); 
        ylabel('m'); 
        title('P(m) versus inverted m', 'FontWeight','normal'); 
        grid on; 
        box on; 
        t1=text(0.02, .98, section_letter    , 'fontsize', 20, 'color', 'r', 'units', 'normalized', 'VerticalAlignment','top'); 
        t2=text(0.98, .98, section_letter+"'", 'fontsize', 20, 'color', 'r', 'units', 'normalized', 'VerticalAlignment','top', 'HorizontalAlignment','right'); 
        
        %% Plot station pdfs. 
        [junk, sta_plot_order] = sort(d_perp); % Order stations from furthest to closest. 
        plot_these_stas = sta_plot_order(junk<offsecmax); % Plot furthest stations first, then closest. 
        
        % Figure out how much to stretch pdfs in plot. 
        pdf_means = nan(length(pdfs),1); 
        for ista = 1:length(pdfs); 
            pm = pdfs(ista).pm; 
            mm = pdfs(ista).mm; 
            cpm = cumtrapz(mm, pm); 
            pdf_means(ista) = mean( pm((cpm>0.1)&(cpm<0.9)) ); 
        end
        pdf_stretch = 1./mean(pdf_means); 
        
        % Plot pdfs. 
        for ista = plot_these_stas(end:-1:1)'; 
        
            mm = pdfs(ista).mm; 
            pm = pdfs(ista).pm; 
        
            mm = reshape(mm, [1, length(mm)]); 
            pm = reshape(pm, [1, length(pm)]); 
        
            cpm = cumtrapz(mm, pm); 
            median_mm = linterp(cpm, mm, 0.5); 
        
            keep_p = (cpm > 0.001) & (cpm < 0.999); % Get rid of 99th percentile to help clean up the plots. 
            mm = mm(keep_p); 
            pm = pm(keep_p); 
            cpm = cpm(keep_p); 
            mm = [mm(1), mm, mm(end)]; 
            pm = [0, pm, 0]; 
            cpm = [0, cpm, 1]; 
        
            all_ms = [all_ms, mm];
            all_pms = [all_pms, pm]; 
            all_cpms = [all_cpms, cpm]; 
        
            xbase = d_par(ista) .* ones(size(pm));
            pm = pm * scale_pdf * pdf_stretch; 
        
            disti = d_perp(ista); 
            dist_rat = disti / offsecmax; 
            face_alpha = 1-dist_rat; 
            face_alpha = face_alpha ^ 2; 
            color = zeros(1,3); 
            edge_alpha = 1 * (disti < 0.25);
        
            fill([xbase + pm; xbase - pm(end:-1:1)]'*convert_deg_km,...
                [mm; mm(end:-1:1)]', color, ...
                'FaceAlpha', face_alpha, ...
                'EdgeColor', 'k', 'EdgeAlpha', edge_alpha); % mean([face_alpha,1])  
            scatter(xbase(1)*convert_deg_km, median_mm, 25, 'r', 'diamond', 'filled', 'MarkerFaceAlpha', face_alpha); 
        end
                
        %% Interpolate model surface to our line section and plot. 
        gcarc = linspace(min(d_par(by_line)), max(d_par(by_line)), n_surf_pts)'; 
        azline = profaz; 
        [lat_surf_line, lon_surf_line] = reckon(Q1(1), Q1(2), gcarc, azline); 
        lat_surf_line_all(:,i_xsect) = lat_surf_line; 
        lon_surf_line_all(:,i_xsect) = lon_surf_line; 
        [vs_surf_line] = griddata(longrid, latgrid, vgrid_out, lon_surf_line, lat_surf_line); 
        
        figure(fnum); % Reopen this figure. 
        plot(gcarc*convert_deg_km, vs_surf_line, 'color', 'blue', 'LineWidth', 3);    
    end % End loop on different sections. 

    min_y = mean(all_ms(all_cpms < 0.01)); 
    max_y = mean(all_ms(all_cpms > 0.99)); 
    y_range = max_y - min_y; 
    figure(fnum); 
    linkaxes(gcf().Children.Children); 
    ylim([min_y - .2 * y_range, max_y + .2 * y_range]); 
    
    
    %% Save figures. 
    exportgraphics(figure(fnum), sprintf('%s/surface_versus_pdf_V%1.0f.pdf', ...
        this_inversion, version_surf),'ContentType','vector'); 
    a3_2_plot_surface_simple(llminmax, 'stalon', mdls.lon, 'stalat', mdls.lat, ...
        'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', vgrid_out,...
        'sectlon', lon_surf_line_all, 'sectlat', lat_surf_line_all); 
    exportgraphics(figure(1   ), sprintf('%s/surface_versus_pdf_mapview_V%1.0f.pdf',...
        this_inversion, version_surf)); 
end
