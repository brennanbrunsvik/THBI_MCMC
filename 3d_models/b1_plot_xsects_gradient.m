% Make cross-sections of velocity model. Show vertical velocity GRADIENT.
% Should be useful for understanding LAB and MLDs. 

clc; clear; 
run('a0_parameters_setup.m'); % !!! Set up all parameters and such in a0. Because there may be many scripts here dependent on those parameters. 
addpath('/Users/brennanbrunsvik/Documents/repositories/Base_code/colormaps/redblue'); 
tectpath1 = "/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/functions/plotting/map_view/whitmeyer_karlstrom/layers/"; % Path to what is currently whitmeyer and karlstrom dataset. 
f_distance_pt_to_sta = './_distance_pt_to_sta.mat';
f_xsect_positions = './xsect_positions.mat'; 

plot_derivatives = true; 

% define colors. 
color_front    = [255, 255, 255]./255; % Grenville Front, Appalachian front.
color_thrust   = [125, 125, 125]./255;
color_mag      = [190, 000, 000]./255;
color_grav     = [000, 150, 000]./255;
color_ha       = [255, 000, 010]./255; % Harrisonburg Anomaly
color_rift     = [255, 111, 000]./255;
if ~plot_derivatives; 
    clim_crust = [3.5, 4.1]; 
    clim_mantle = [4.25, 4.75];
else
    clim_crust = [-0.05, 0.05]; 
    clim_mantle = [-0.005, 0.005];
end

version_surf = 7; 
max_z = 250; 

% Define any colors. 
clr_tectfiles = struct("grv_frt", color_front, "MCR", color_rift, ...
    "Reelfoot", color_rift, "something_province", color_thrust); % Field names have to precicely correspond to file names from this tectonic dataset. 

%%% Cross section stuff, copy to cross-section code. 
version_surf = 7; 
ll_min_max_map = [-89  -72   32   46]; % Map view
lobase = [-87, -76]; 
labase = [ 43,  35]; 
vdx = 1; 
vdy = 0.8;
dshifts = [-4, -2, 0, 1.5]'; 
lolim = lobase + vdx * dshifts; 
lalim = labase + vdy * dshifts; 

% How far from stations will we plot model? in km. Maybe not in use in this
% script yet? 
min_sta_dist_plt = 50; % Half-distance between TA stations? 

n_contour = 30; 

depths = [5:5:300]; dz = diff(depths); 
depth_plot = 80; 
idepth_plot = find(depths==depth_plot); 
parms_other = ["zsed", "zmoh"]; 

sfsmat = load('surface_out_example.mat'); xgrid = sfsmat.xgrid; ygrid = sfsmat.ygrid; llminmax = sfsmat.llminmax; latgrid = sfsmat.latgrid; longrid = sfsmat.longrid; 
mdls = load(fresults).mdls; % For sta lon and lat so we know where to and not to plot. 

f_3d_model = [pwd() , '/surface_colated_b1_V' , num2str(version_surf) , '.mat']; 

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
    sfsmat2= load(sprintf('%s/surface_values_V%1.0f', this_inversion, version_surf)); 
    mgrid_out = sfsmat2.mgrid_out; 
    mgrid3d(:,:,idep) = mgrid_out; 
end


% Make mgrid3d derivatives
if plot_derivatives; 
    dz3d = reshape(dz,1,1,length(dz)); 
    dgrid = (mgrid3d(:,:,2:end)-mgrid3d(:,:,1:end-1)) ./dz3d; 

    dmgrid3d = zeros(size(z3d)); 
    dmgrid3d(:,:,1:end-1) = dmgrid3d(:,:,1:end-1) + dgrid; 
    dmgrid3d(:,:,2:end  ) = dmgrid3d(:,:,2:end  ) + dgrid; 
    dmgrid3d(:,:,2:end-1) = dmgrid3d(:,:,2:end-1) / 2; 
    mgrid3d = dmgrid3d; % For each code manipulation
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

%% Save 3-D info, borders, cross-sections, whatever, to plot with Plotly
if ~plot_derivatives; 
    save(f_3d_model, 'mgrid3d', 'lat3d', 'lon3d', 'z3d', ...
        'latgrid', 'longrid', 'xgrid', 'ygrid', 'depths', ...
        'zmoh_surf', 'zsed_surf'); 
end

%%
figure(16); clf; hold on; 
set(gcf, 'pos', [493 109 674 963]); % Roughly 8.5 by 11
tiledlayout(size(lolim, 1 ), 1,'TileSpacing', 'Compact')

% Redefine cross-sections so they don't go out of where we have constraints. 
for ixsect = 1:size(lolim,1); 
    [profd,profaz] = distance(lalim(ixsect,1),lolim(ixsect,1),lalim(ixsect,2),lolim(ixsect,2));
    gcarc = linspace(0, profd, 500)'; 
    [lat_surf_line, lon_surf_line] = reckon(lalim(ixsect, 1), lolim(ixsect,1), gcarc, profaz);
    section_distances = nan(size(lat_surf_line)); 
    for ipt = 1:length(lat_surf_line); 
        section_distances(ipt) = min(...
                distance(lat_surf_line(ipt), lon_surf_line(ipt), ...
                mdls.lat, mdls.lon ),...
            [], 'all')*6371*2*pi/360; % Fast enough. 
    end
    keep_sect = section_distances < min_sta_dist_plt; 
    keep_sect = find(keep_sect); 
    lolim(ixsect, 1) = lon_surf_line(keep_sect(1)); 
    lolim(ixsect, 2) = lon_surf_line(keep_sect(end)); 
    lalim(ixsect, 1) = lat_surf_line(keep_sect(1)); 
    lalim(ixsect, 2) = lat_surf_line(keep_sect(end)); 
end
save(f_xsect_positions, 'lolim', 'lalim'); 

nxy = 100; 
lat_surf_line_all = zeros(nxy, size(lolim,1) ); 
lon_surf_line_all = lat_surf_line_all; 

% Organize subplots
bord_width = 3; 
buffplt = 0.05; 

n_sections = size(lolim, 1) ; 
ax_x  = [0.07 ] * ones([1, n_sections]); 
ax_y = 0.1 + .185*[0:length(ax_x)-1]; 
ax_dy = [0.15] * ones([1, n_sections]); 
ax_dx = nan(size(ax_dy)); 

for i_xsect = 1:n_sections;
    
    %%% Pre-plot prep
    % Conversions from xy and latlon
    Q1 = [lalim(i_xsect, 1), lolim(i_xsect, 1)];
    Q2 = [lalim(i_xsect, 2), lolim(i_xsect, 2)]; 
    [profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
    gcarc = linspace(0, profd, nxy)'; 
    d2km = 2 * pi * 6371 / 360; 
    dist_arc = d2km * gcarc; % km , 1-d
    [lat_surf_line, lon_surf_line] = reckon(Q1(1), Q1(2), gcarc, profaz); 
    lat_surf_line_all(:,i_xsect) = lat_surf_line; 
    lon_surf_line_all(:,i_xsect) = lon_surf_line; 
    
    % Prepare a 2-D VS section for interpolation
    zsect = linspace( min(depths), max(depths), nxy-1); 
    [lonmesh, zmesh ] = ndgrid(lon_surf_line, zsect); 
    [latmesh, ~] = ndgrid(lat_surf_line, zsect); 
    [gcmesh , ~] = ndgrid(gcarc        , zsect); 
    mterp = griddata(lon3d, lat3d, z3d, mgrid3d, lonmesh, latmesh, zmesh); % Interpolated section
    
    % Station distance and position along line
    slon = mdls.lon; 
    slat = mdls.lat;
    sta_x_ind = zeros(size(slon)); 
    sta_dists = zeros(size(slon)); 
    sta_cutoff = 70; 
    for ista = 1:length(slon); 
        [stadist] = distance(slat(ista), slon(ista), lat_surf_line, lon_surf_line);
        % stadist = stadist 
        close_point = find(min(stadist) == stadist); 
        stadist = stadist(close_point);
        stadist = stadist * 6371 * 2 * pi / 360; 
        sta_dists(ista) = stadist; 
        sta_x_ind(ista) = close_point; 
    end
    plt_sta_bool = sta_dists <= sta_cutoff; 
    sta_dists = sta_dists(plt_sta_bool); 
    sta_x_ind = sta_x_ind(plt_sta_bool); 
    sta_x_dist = dist_arc(sta_x_ind); 
    
    dist_sect = gcmesh*d2km; % For plotting along section. 2-d
    
    % Interpolate sediment, zmoh, topography
    zmohsect = griddata(longrid, latgrid, zmoh_surf, lon_surf_line, lat_surf_line); 
    zsedsect = griddata(longrid, latgrid, zsed_surf, lon_surf_line, lat_surf_line); 
    ztopsect = interpn (lon_top, lat_top, z_top    , lon_surf_line, lat_surf_line, 'cubic'); % can use interpn here for speed because topo is on a grid. But the surface I inverted isn't on a lon/lat grid (it's a linearly spaced grid in x and y), so we have to use griddata above. 
    ztopsect_scaled = -(ztopsect/50)-10; % Scale topography
    
    % Set up axes
    axxlims = [min(dist_arc), max(dist_arc)]; 
    axylims = [-50, max_z]; 
    ax_dx(i_xsect) =  ax_dy(i_xsect) * (diff(axxlims)/diff(axylims)); 
    ax_box = axes('Position',[ax_x(i_xsect), ax_y(i_xsect), ...
        ax_dx(i_xsect), ax_dy(i_xsect)]); 
    
    set(ax_box, 'YDir', 'reverse'); 
    ax_mantle = copyobj(ax_box, gcf); hold on; % Displayed in middle order.  
    ax_crust = copyobj(ax_box, gcf); hold on; 
    linkaxes([ax_box, ax_mantle, ax_crust]); 
    
    %%% Plot velocity
    rbmap = redblue(); %rbmap = redblue(n_colors); 
    colormap(rbmap); 
    
    % Mantle contour. Could do a loop. 
    ismantle = zmohsect < zmesh; 
    iscrust  = zmohsect > zmesh; 
    mterpcrust  = mterp; 
    mterpmantle = mterp; 
    mterpcrust (~iscrust ) = nan; 
    mterpmantle(~ismantle) = nan; 
    [fk, hand] = contourf(ax_crust , gcmesh*d2km, zmesh, mterpcrust , 200, 'EdgeAlpha', 0.1); 
    [fk, hand] = contourf(ax_mantle, gcmesh*d2km, zmesh, mterpmantle, 200, 'EdgeAlpha', 0.1); 
    set(ax_crust , 'ydir', 'reverse'); % For some reason contourf occasionally flips figure to unreverse. 
    set(ax_mantle, 'ydir', 'reverse'); % For some reason contourf occasionally flips figure to unreverse. 
    
    %%% Plot other things
    moh_color = [250, 2, 192]/250; 
    plot(ax_box, gcarc*d2km, zmohsect, 'color', moh_color, 'LineWidth', 4); % Moho
    plot(ax_box, gcarc*d2km, ztopsect_scaled, 'k', 'LineWidth', 3); % Topography
    
    % Plot stations
    sta_y_plt = interp1(dist_arc, ztopsect_scaled, sta_x_dist); 
    fck = scatter(ax_box, sta_x_dist, sta_y_plt-10, ...
        'marker', '^', 'CData', [0,0,0], 'SizeData', 20, 'LineWidth', 0.25); 
    
    % Tectonic borders
    for ibord = 1:2
        if ibord == 1; 
            bord = app_bord; 
            textplt = 'AF'; 
        elseif ibord == 2; 
            bord = gre_bord; 
            textplt = 'GF'; 
        end
        [profd_bord,profaz_bord] = distance(Q1(1),Q1(2),bord(2,:), bord(1,:)); % Distance from origin, and azimuth. 
        bord_dist = d2km * interp1(profaz_bord, profd_bord, profaz, 'spline');  % Interpolate for the borders distance where the azimuth matches this sections azimuth. 
        bord_height = interp1(dist_arc, ztopsect_scaled, bord_dist); % Plot at top of topography
        scatter(ax_box, bord_dist, bord_height, ...
            450, 'k', '|', 'linewidth', bord_width); 
        text(ax_box, bord_dist+13, 5, textplt, ...
            'HorizontalAlignment','left', 'VerticalAlignment','bottom', ...
            'FontSize',6); 
    
    end
    
    % % Continent ocean transition, based on topography
    plot_COT = false; 
    if plot_COT; 
        is_land = find(ztopsect > 0); 
        last_land = is_land(end);
        fprintf('COT determination - assuming ocean is on the high dist_arc side of section.')
        if last_land < length(lon_surf_line); % Ignore if it's the last index
            ocean_x = dist_arc(last_land); 
            ocean_y = ztopsect_scaled(last_land); 
            scatter(ax_box, ocean_x, ocean_y, ...
                450, 'k', '|', 'linewidth', bord_width); 
            text(ax_box, ocean_x - 20, ocean_y-20, 'COT', 'HorizontalAlignment', 'Right', 'FontSize', 11); 
        end
    end
    
    % Section letters. 
    section_letter = char(64+i_xsect); % Text for cross-section name. ith letter of alphabet
    t1=text(ax_box, 0.01, 1.12, section_letter    , 'fontsize', 14, 'color', 'k', 'units', 'normalized', 'VerticalAlignment','top'); 
    t2=text(ax_box, 0.99, 1.12, section_letter+"'", 'fontsize', 14, 'color', 'k', 'units', 'normalized', 'VerticalAlignment','top', 'HorizontalAlignment','right'); 
    
    % Exageration
    dexag = 25; 
    plot(ax_box, [min(dist_arc)+dexag, min(dist_arc)+dexag] , [max_z, max_z-dexag], 'k', 'linewidth', 1.5); 
    plot(ax_box, [min(dist_arc), min(dist_arc)+dexag] , [max_z-dexag, max_z-dexag], 'k', 'linewidth', 1.5); 
    
    linkaxes([ax_box, ax_mantle, ax_crust]); % done already, but I guess do it again. 
    axes(ax_crust); axes(ax_mantle); axes(ax_box); 
    
    % Some axis set up that only works after plots are made for some reason
    ax_box.Visible = 'on' ; ax_mantle.Visible = 'off'; ax_crust.Visible = 'off'; 
    ax_box.Color = 'none'; ax_mantle.Color = 'none'; ax_crust.Color = 'none'; 
    box(ax_box, 'on'); 
    set(ax_box, 'LineWidth', 1.5); 
    ylim(ax_box, axylims); 
    xlim(ax_box, axxlims);
    
    clim(ax_crust , clim_crust ); 
    clim(ax_mantle, clim_mantle); 
    
    % Change topo labels
    ax_box.YTick = [0:50:10000]; % Steps of 50, starting at 0. Nothing for topography. 
    
    ylabel('Depth (km)'); 
    if i_xsect == 1; 
        xlabel('Distance (km)'); 
    end

end

% Colorbars if vertical
cbar_crust  = colorbar(ax_crust ,'Location', 'east'); 
cbar_mantle = colorbar(ax_mantle,'Location', 'east'); 
cbar_crust.Position      = [ax_dx(end) + 0.08  , ax_y(end), .0175, ax_dy(1)]; 
cbar_mantle.Position     = [ax_dx(end) + 0.15 , ax_y(end), .0175, ax_dy(1)]; 
cbar_crust.Label.String  = 'Crust Vs' ; 
cbar_mantle.Label.String = 'Mantle Vs'; 

%% Map view of cross-section locations. 
axmap = axes('Position', [ax_dx(1)+0.1, (ax_y(1)), ax_dy(1)*.8, ax_dy(1)*.8]);
cla; hold on; 
m_proj('mercator', 'long',[ll_min_max_map(1)-1, ll_min_max_map(2)+1],...
                   'lat',[ll_min_max_map(3)-2, ll_min_max_map(4)]); 

[latbord, lonbord] = borders('states'); % add states map
for iplace = 1:length(lonbord); 
    m_line(lonbord{iplace}, latbord{iplace}, 'LineWidth',1,'color',.5*[1 1 1])
end
cst = m_coast('patch',.5*[1 1 1], 'FaceAlpha', 0); 
xsect_letters = ["A", "B", "C", "D", "E", "F", "G", "H"]; 
for ixsect = 1:size(lolim,1); 
    Q1 = [lalim(ixsect, 1), lolim(ixsect, 1)];
    Q2 = [lalim(ixsect, 2), lolim(ixsect, 2)]; 
    [profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
    gcarc = linspace(0, profd, 100)'; 
    d2km = 2 * pi * 6371 / 360; 
    dist_arc = d2km * gcarc; % km 
    [lat_surf_line, lon_surf_line] = reckon(Q1(1), Q1(2), gcarc, profaz); 
    m_plot(lon_surf_line, lat_surf_line, 'k', 'linewidth', 2); 
    m_text(lon_surf_line(1 )-.75, ...
        lat_surf_line(1  )-0, ...
        xsect_letters(ixsect), ...
        'color', 'k', 'fontweight', 'normal', 'units', 'data', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'fontsize', 8); 
    m_text(lon_surf_line(end) +1.75, ...
        lat_surf_line(end),...
        xsect_letters(ixsect)+"'", ...
        'color', 'k', 'fontweight', 'normal', 'units', 'data', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'fontsize', 8);  
end
m_grid('box','fancy','linestyle','none','gridcolor',.5 .*[1,1,1],...
    'backcolor','none', 'xtick', [-85:10:75], 'ytick', [35:10:45], ...
    'fontsize', 8, 'ylabeldir', 'middle', 'YaxisLocation', 'right'); 

mkdir('xsections'); 
exportgraphics(gcf, sprintf('model_output/xsections_V%1.0f.jpeg', version_surf), ...
    'Resolution', 600); 
savefig(gcf, sprintf('model_output/xsections_V%1.0f.fig', version_surf)); 

%% Plot of cross-section positions
a3_2_plot_surface_simple(llminmax, 'stalon', mdls.lon, 'stalat', mdls.lat, ...
    'xgrid', xgrid, 'ygrid', ygrid, 'vgrid', mgrid3d(:, :, idepth_plot),...
    'sectlon', lon_surf_line_all, 'sectlat', lat_surf_line_all); 
text(0.75, 0.1, sprintf('Z=%1.0f km',depth_plot), 'Units', 'normalized'); 
set(gcf, 'pos',[295 476 426 321]); 
exportgraphics(gcf, sprintf('model_output/xsections_map_V%1.0f.pdf', version_surf)); 
fprintf('\n'); 