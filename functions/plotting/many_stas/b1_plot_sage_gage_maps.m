clc; clear; restoredefaultpath; 
run('a0_parameters_setup.m'); % !!! Set up all parameters and such in a0. Because there may be many scripts here dependent on those parameters. 
addpath('/Users/brennanbrunsvik/Documents/repositories/Base_code/colormaps/redblue'); 
version_surf = 7; 
% lolim = [-87, -76; -86, -68; -88, -78; -87, -80.5]; 
% lalim = [ 43,  35;  30,  47;  36,  33;  38,  25  ]; 

ll_min_max_map = [-89  -72   32   46]; % Map view
lobase = [-87, -76]; 
labase = [ 43,  35]; 
vdx = 1; 
vdy = 0.8;
dshifts = flip([-7, -5, -3, -1, 0, 1, 5, 7]'); 
lolim = [-87, -76]; 
lalim = [ 43,  35]; 

n_contour = 30; 

% depths = [5, 15, 20, 25, 30, 35, 40, ...
%         45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 110, 120, 130, 145, 170, 210, 250, 300]; % Try loading these depths. Probably need to type manually for now, but could save as a .mat file in future. 
% depth_plot = 80; 
depths = [25, 95, 145]; % Try loading these depths. Probably need to type manually for now, but could save as a .mat file in future. 
% depth_plot = 80; 
% idepth_plot = find(depths==depth_plot); 
parms_other = ["zsed", "zmoh"]; 

sfsmat = load('surface_out_example.mat'); xgrid = sfsmat.xgrid; ygrid = sfsmat.ygrid; llminmax = sfsmat.llminmax; latgrid = sfsmat.latgrid; longrid = sfsmat.longrid; 
mdls = load(fresults).mdls; % For sta lon and lat so we know where to and not to plot. 

kmall = readgeotable('/Users/brennanbrunsvik/Downloads/doc.kml'); % As far as I got on 2023/01/21 to load the kmal file from Whitmeyr and Karlstrom

%% Make 3d lat and lon grids. 
nz = length(depths); 
mgrid3d = zeros(size(latgrid,1), size(latgrid,2), nz); 
lat3d   = zeros(size(latgrid,1), size(latgrid,2), nz); 
lon3d   = zeros(size(latgrid,1), size(latgrid,2), nz); 
z3d     = zeros(size(latgrid,1), size(latgrid,2), nz); 
for iz = 1:nz; 
    lat3d(:,:,iz) = latgrid; 
    lon3d(:,:,iz) = longrid; 
    z3d(:,:,iz) = depths(iz); 
end

for idep = 1:length(depths); 
dep = depths(idep); 

this_inversion = sprintf('vs%1.0f',dep); 
sfsmat2= load(sprintf('%s/surface_values_V%1.0f', this_inversion, version_surf)); mgrid_out = sfsmat2.mgrid_out; 

mgrid3d(:,:,idep) = mgrid_out; 

end

% Load crust, sed
sfsmat2 = load(sprintf('zmoh/surface_values_V%1.0f', version_surf)); 
zmoh_surf = sfsmat2.mgrid_out; 
sfsmat2 = load(sprintf('zsed/surface_values_V%1.0f', version_surf)); 
zsed_surf = sfsmat2.mgrid_out; 

% Load topo
[lon_top, lat_top, z_top...
    ] = get_z_etopo1(min(longrid(:))-1, max(longrid(:))+1, ...
             min(latgrid(:))-1, max(latgrid(:))+1, 'plot', false,...
             'ndmesh', true); 


%% Any borders to plot
%brb2023.02.21 These were copied from the 2021 ENAM paper. They were made only roughly, so I need more accurate shape files. 
app_bord = [-73.9819443, -74.619146 , -75.520073 , -76.1132732, -76.7944389,-77.1789631, -77.6294266, -77.9920049, -78.2117582, -78.4383114,-79.1416076, -79.8888598, -80.2331436, -80.7605221, -81.2438831,-81.9140786, -82.4853569, -83.2434644, -84.3284171, -84.7700317,-85.1106908, -85.5944904, -86.0889287, -87.330563; 40.4970924,  40.7306085,  40.9467137,  41.1455697,  41.2695495,41.2365112,  41.0959121,  40.8719878,  40.7056279,  40.3967643,39.5548831,  38.4965935,  38.1259146,  37.7272803,  37.5445773,37.3439591,  37.1603165,  36.8268747,  36.1733569,  35.880149 ,35.4427709,  34.7777158,  34.1799976,  32.9349287]; 
gre_bord = [-82.8790832, -83.5164453, -83.6483134, -84.0878735, -84.3516096, -85.714246 , -87.3406184, -88.1098487; 43.9928145,  41.8040781,  40.8969058,  39.6733704,  38.9764925, 36.6155276,  34.9940038,  34.3978449]; 

%%
% ll_min_max_map = [-86  -76   28   47]; % Map view
% best_aspect = 0.7008; % ax = gca; best_aspect = ax.Position(3) / ax.Position(4);
% proj_out = m_proj('oblique mercator', 'long',[ll_min_max_map(2), ll_min_max_map(1)],...
%                    'lat',[ll_min_max_map(4), ll_min_max_map(3)],...
%                    'aspect', best_aspect);


ll_min_max_map = [-89  -68   26   46]; % Map view
figure(17); clf; hold on; set(gcf,'pos', [87 856 692 476]); 
tiledlayout(2, 3, 'TileSpacing', 'tight'); 


pt_dist_nan = 1; 
pt_dist = zeros(size(grd_cont)); 
for ipt = 1:(size(xgrid, 1) * size(xgrid,2)); 
    pt_dist(ipt) = min(distance(latgrid(ipt), longrid(ipt), ...
        mdls.lat, mdls.lon));
end

for ifig = 1:6; 
% tickon = ["off", "off", "off", "on", "on", "on"; "on", "off", "off", "on", "off", "off"]; % tickon(1,2) is xticks, 2nd axis. tickon(2,3) would be yticks, 3rd axis. 
% xticks(tickon(1,ifig)); 
% yticks(tickon(2,ifig)); 
% xticklabels('')
nexttile(); hold on; box on; set(gca, 'LineWidth', 1.5);
m_proj('mercator', 'long',[ll_min_max_map(1), ll_min_max_map(2)],...
                   'lat',[ll_min_max_map(3), ll_min_max_map(4)]);
m_coast('patch',[1 1 1]); 

% Pick the right surface. 
if ifig >=4; 
    ind_depth = ifig-3; 
    grd_cont = mgrid3d(:,:,ind_depth); 
    label = string(sprintf('Z=%1.0f km', depths(ind_depth))) + newline + "Vs (km/s)"; 
    cmap = turbo(); 
    cmap = flip(cmap); 
    colormap(gca, cmap); 
    if ind_depth == 1; 
        caxis([3.6, 3.9]); 
    elseif any(ind_depth == [2,3]); 
        caxis([4.35, 4.75]); 
    end
elseif ifig == 1; 
    grd_cont = zmoh_surf; 
    label = 'Moho (km)'; 
    colormap(gca, viridis); 
%     caxis([])
elseif ifig == 2; 
    grd_cont = zsed_surf;
    label = "Sediment (km)"; 
    colormap(gca, viridis); 
%     set(gca,'ColorScale','log'); Later could make this log... 
    caxis([0, 1]); 
elseif ifig == 3; 
    grd_cont = zmoh_surf; % TEMPORARY 
    label = '\xi=(Vsh/Vvh)^2'; 
    colormap(gca, redblue()); 
    caxis([0.9, 1.1]); 
end
grd_cont(pt_dist > pt_dist_nan) = nan; 
% Colorbar and label
ax = gca(); 

cbar = colorbar('Location', 'south'); 
cbar.Position(3) = ax.Position(3) * .4; 
% disp(cbar.Position)
cbar.Position(1) = (ax.Position(1)+ax.Position(3)*.5) ; 

options.vgrid(pt_dist > pt_dist_nan) = nan; 

num_cnt = 100; 
m_contourf(longrid, latgrid, grd_cont, num_cnt,...
    'LineStyle','none'); 

% States
[latbord, lonbord] = borders('states'); % add states map
for iplace = 1:length(lonbord); 
    m_line(lonbord{iplace}, latbord{iplace}, 'LineWidth',1,'color',0*[1 1 1])
end


% Cross section position
if ifig == 1; 
    Q1 = [lalim(1, 1), lolim(1, 1)];
    Q2 = [lalim(1, 2), lolim(1, 2)]; 
    [profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
    gcarc = linspace(0, profd, 100)'; 
    d2km = 2 * pi * 6371 / 360; % Yes I know this is 111, but might as well be somewhat precise :) 
    dist_arc = d2km * gcarc; % km 
    [lat_surf_line, lon_surf_line] = reckon(Q1(1), Q1(2), gcarc, profaz); 
    m_plot(lon_surf_line, lat_surf_line, 'k', 'linewidth', 2); 
    m_text(lon_surf_line(1  )  , lat_surf_line(1  )-1, 'A', ...
        'color', [1,1,1], 'fontweight', 'bold', 'units', 'data'); 
    m_text(lon_surf_line(end)-2, lat_surf_line(end)  , "B", ...
        'color', [1,1,1], 'fontweight', 'bold', 'units', 'data'); 
end

% Stations
if ifig == 2; 
    m_scatter(mdls.lon, mdls.lat, 5, 'k', 'filled'); 
end

% if ifig == 1; 
    m_plot(app_bord(1,:), app_bord(2,:), 'linewidth', 3, 'color', [102, 45, 1]./255); 
    m_plot(gre_bord(1,:), gre_bord(2,:), 'linewidth', 3, 'color', [102, 45, 1]./255); 
% end
if ifig == 1; 
    m_text(-83, 41, 'GRNVL', 'color', [1,1,1]); 
    m_text(-85, 35, 'APPLN', 'color', [1,1,1]); 

end


m_text(-74, 30.5, label, 'Units','data', 'HorizontalAlignment', 'center',...
    'VerticalAlignment', 'bottom'); 


xtck = [-88:6:-68]; 
ytck = [28:4:44]; 
xtckstr = xtck; 
ytckstr = ytck; 
xtckcel = {[], [], [], xtckstr, xtckstr, xtckstr}; 
ytckcel = {ytckstr, [], [], ytckstr, [], []}; 

m_grid('box','fancy','linestyle','none','gridcolor',.5 .*[1,1,1],...
    'backcolor',[.3 .75 1], 'xticklabel', xtckcel{ifig}, 'yticklabel', ytckcel{ifig},...
    'xtick', xtck, 'ytick', ytck);
end

exportgraphics(gcf, sprintf('sage_gage/map_view_V%1.0f.pdf', version_surf), ...
    'Resolution',500); 


% % % % set(gcf, 'pos', [1053 564 767*2 329*ceil(.5*size(lolim,1))], 'color', 'white'); 
% % % % tiledlayout(ceil(.5 * size(lolim, 1 )), 2,'TileSpacing', 'Compact')
% % % set(gcf, 'pos', [1053 564 767 260*size(lolim,1)])
% % % tiledlayout(size(lolim, 1 ), 1,'TileSpacing', 'Compact')
% % % 
% % % nxy = 100; 
% % % lat_surf_line_all = zeros(nxy, size(lolim,1) ); 
% % % lon_surf_line_all = lat_surf_line_all; 
% % % 
% % % % for i_xsect = 1; 
% % % % for i_xsect = 1:size(lolim, 1); 
% % % i_xsect = 1; 
% % % 
% % % 
% % % 
% % % Q1 = [lalim(i_xsect, 1), lolim(i_xsect, 1)];
% % % Q2 = [lalim(i_xsect, 2), lolim(i_xsect, 2)]; 
% % % [profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
% % % 
% % % gcarc = linspace(0, profd, nxy)'; 
% % % d2km = 2 * pi * 6371 / 360; % Yes I know this is 111, but might as well be somewhat precise :) 
% % % dist_arc = d2km * gcarc; % km 
% % % 
% % % [lat_surf_line, lon_surf_line] = reckon(Q1(1), Q1(2), gcarc, profaz); 
% % % 
% % % lat_surf_line_all(:,i_xsect) = lat_surf_line; 
% % % lon_surf_line_all(:,i_xsect) = lon_surf_line; 
% % % 
% % % 
% % % %%% Prepare a 2-D section to interpolate into. 
% % % 
% % % 
% % % % Simplest section
% % % % lonsect = linspace( min(min(longrid))+1, max(max(longrid))-1, nxy ); 
% % % % latsect = linspace( max(max(latgrid))+1, min(min(latgrid))-1, nxy ); 
% % % zsect = linspace( min(depths), max(depths), nxy-1); 
% % % 
% % % [lonmesh, zmesh ] = ndgrid(lon_surf_line, zsect); 
% % % [latmesh, zmesh2] = ndgrid(lat_surf_line, zsect); 
% % % [gcmesh , zmesh3] = ndgrid(gcarc        , zsect); 
% % % 
% % % mterp = griddata(lon3d, lat3d, z3d, mgrid3d, lonmesh, latmesh, zmesh); 
% % % 
% % % 
% % % 
% % % 
% % % %%% Interpolate sediment, zmoh
% % % zmohsect = griddata(longrid, latgrid, zmoh_surf, lon_surf_line, lat_surf_line); 
% % % zsedsect = griddata(longrid, latgrid, zsed_surf, lon_surf_line, lat_surf_line); 
% % % ztopsect = interpn (lon_top, lat_top, z_top    , lon_surf_line, lat_surf_line, 'cubic'); % can use interpn here for speed because topo is on a grid. But the surface I inverted isn't on a lon/lat grid (it's a linearly spaced grid in x and y), so we have to use griddata above. 
% % % ztopsect_scaled = -(ztopsect/50)-10; 
% % % %%%
% % % 
% % % 
% % % %%% Plot
% % % % figure(1); clf; hold on; 
% % % nexttile(); hold on; 
% % % box on; 
% % % set(gca, 'LineWidth', 1.5, 'YDir', 'reverse'); 
% % % xlabel('Distance (km)'); 
% % % ylabel('Depth (km)'); 
% % % title('Vs cross-section')
% % % 
% % % 
% % % clim_min = 3.9; 
% % % clim_max = 4.75; 
% % % step_contour = 0.025; 
% % % % v_contours = [clim_min:0.05:clim_max]; 
% % % v_contours = [0:step_contour:10]+0.5*step_contour; 
% % % clim([clim_min, clim_max]); % TODO temporary 
% % % n_colors = (clim_max - clim_min) / step_contour; 
% % % 
% % % turbo_map = turbo(n_colors); 
% % % turbo_map = turbo_map(end:-1:1,:); 
% % % colormap(turbo_map);
% % % cbar = colorbar(); 
% % % cbar.Label.String = 'Vs'; 
% % % 
% % % 
% % % % Velocity
% % % % [fk, hand] = contourf(gcmesh*d2km, zmesh, mterp, n_contour, 'EdgeAlpha', 0.5); 
% % % % [fk, hand] = contourf(gcmesh*d2km, zmesh, mterp, v_contours, 'EdgeAlpha', 0.5); 
% % % [fk, hand] = contourf(gcmesh*d2km, zmesh, mterp, v_contours, 'EdgeAlpha', 0.1); 
% % % 
% % % 
% % % % Moho
% % % moh_color = [250, 2, 192]/250; 
% % % plot(gcarc*d2km, zmohsect, 'color', moh_color, 'LineWidth', 4); 
% % % % plot(gcarc*d2km, zsedsect*1000/50 - 10, 'color', [235, 164, 52]./255, 'LineWidth', 3); % [2, 217, 250]/255
% % % plot(gcarc*d2km, ztopsect_scaled, 'k', 'LineWidth', 3); 
% % % % yyaxis right; % Maybe this can be a useful way to put sediment and stuff
% % % % with different veritcal scaling. 
% % % % yyaxis left; 
% % % 
% % % 
% % % %%% Interpolate borders
% % % for ibord = 1:2
% % %     if ibord == 1; bord = app_bord; elseif ibord == 2; bord = gre_bord; end
% % %     [profd_bord,profaz_bord] = distance(Q1(1),Q1(2),bord(2,:), bord(1,:)); % Distance from origin, and azimuth. 
% % %     bord_dist = d2km * interp1(profaz_bord, profd_bord, profaz, 'spline');  % Interpolate for the borders distance where the azimuth matches this sections azimuth. 
% % %     bord_height = interp1(dist_arc, ztopsect_scaled, bord_dist); % Plot at top of topography
% % %     scatter(bord_dist, bord_height, ...
% % %         450, 'k', '|', 'linewidth', 8); 
% % %     % figure(31); clf; hold on; 
% % %     % scatter(bord(1,:), bord(2,:)); 
% % %     % scatter(lon_surf_line_all, lat_surf_line_all)
% % %     %%%
% % % end
% % % 
% % % 
% % % section_letter = char(64+i_xsect); % Text for cross-section name. ith letter of alphabet
% % % t1=text(0.01, 1.12, section_letter    , 'fontsize', 20, 'color', 'r', 'units', 'normalized', 'VerticalAlignment','top'); 
% % % t2=text(0.99, 1.12, section_letter+"'", 'fontsize', 20, 'color', 'r', 'units', 'normalized', 'VerticalAlignment','top', 'HorizontalAlignment','right'); 
% % % 
% % % 
% % % ylim([-70, 300]); 
% % % text(400, -40, 'Grenville', 'HorizontalAlignment', 'left', 'FontSize', 11); 
% % % text(830, -40, 'Appalachians', 'HorizontalAlignment', 'left', 'FontSize', 11); 
% % % text(1270, 40, 'Moho', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontSize', 13, 'color', moh_color); 
% % % 
% % % % end
% % % 
% % % linkaxes(gcf().Children.Children); 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % mkdir('xsections'); 
% % % exportgraphics(gcf, sprintf('xsections/xsections_V%1.0f.pdf', version_surf), 'Resolution', 300); 


% % % %% Plot of cross-section positions
% % % % ll_min_max_map
% % % a3_2_plot_surface_simple(llminmax, 'stalon', mdls.lon, 'stalat', mdls.lat, ...
% % %     'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', mgrid3d(:, :, idepth_plot),...
% % %     'sectlon', lon_surf_line_all, 'sectlat', lat_surf_line_all); 
% % % text(0.75, 0.1, sprintf('Z=%1.0f km',depth_plot), 'Units', 'normalized'); 
% % % set(gcf, 'pos',[295 476 426 321]); 
% % % exportgraphics(gcf, sprintf('xsections/xsections_map_V%1.0f.pdf', version_surf)); 
% % % fprintf('\n'); 


% function []=newtile(); 
% nexttile(); 
% hold on; 
% box on; 
% set(gca, 'LineWidth', 1.5);
% end