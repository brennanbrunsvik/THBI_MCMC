%% Pseudo cross section for all sites with inversions along section
clear;close all

run("../../a0_STARTUP_BAYES.m"); 

%% Setup
paths = getPaths(); 
proj = load('~/Documents/UCSB/ENAM/THBI_ENAM/ENAM/INFO/proj.mat'); 
proj = proj.proj; 
paths.STAinversions = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_collate/'; % Place where your results are. 
proj.STAinversions = paths.STAinversions; 

figPath = '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/figures/xsect/'; warning('Export path not relative path')
    
addpath('~/MATLAB/m_map');
addpath('~/Documents/UCSB/ENAM/THBI_ENAM/functions'); 
addpath('~/MATLAB/seizmo/cmap'); warning('adding cmap in seismo. Is this breaking split?'); 
addpath('~/MATLAB/borders'); 
addpath('/Users/brennanbrunsvik/Documents/repositories/general_data'); % For topography loading. get_z_etopo1.m

% specify details of this run
generation = 1; % generation of solution and data processing
STAMP = 'standard';

% Quality thresholds for including stations - important!
overallQ_thresh = 1; % 2 is good, 1 is ok, 0 is bad
Sp_Q_thresh = 1; % Sp data quality (same bounds as above)

vlims = [4.15 4.8];
vcmp = flipud(jet);
ccplim = 12;
ccpcmp = cmap_makecustom([0 0 1],[1 0 0],0.1);

ifsave = true;

%% lon/lat limits on stations to include:
lolim = [-87, -76]; 
lalim = [35, 43]; 
%% section ends
% WNW to ESE across whole region
ofile1 = [figPath 'Xsect1_',STAMP];
ofile2 = [figPath 'Xsect1_wCCP_',STAMP];
Q1 = [lalim(2), lolim(1)];
Q2 = [lalim(1), lolim(2)]; 
offsecmax = 3; % distance off section allowed, in degrees


% profile deets
[profd,profaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));

% output names of stations
ostafile = [figPath 'stafile_',STAMP,'.txt'];

%% load project & station details
infodir = '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/ENAM/INFO/'; 
stations = load([infodir 'stations.mat']); 
stainfo = stations.stainfo; 
stainfo.overallQ = ones(size(stainfo.slons)); 

% retrieve comparison models
semPath = '~/Documents/repositories/data/models_seismic/SEMum2_avg_VS'
addpath(semPath); 
a = SEMum2_avgprofiles(0,[semPath '/']);

%%
%%% Making my own map brb2022.03.08
mapFigNum = 1001; 
figure(mapFigNum); clf; hold on; set(gcf, 'color', 'white', 'pos', [-1152 439 378 369]); 
m_proj('lambert','long',lolim + [-2 2],'lat',lalim + [-2 2]);
m_coast('patch',[1 .85 .7]);

[latbord, lonbord] = borders('states'); % add states map
for iplace = 1:length(lonbord); 
    m_line(lonbord{iplace}, latbord{iplace}, 'LineWidth',1,'color',0*[1 1 1])
end

lineCol = [168, 58, 50]./255; 
sectLine = m_line([Q1(2) Q2(2)], [Q1(1), Q2(1)]); 
set(sectLine, 'LineWidth', 3, 'color', lineCol); 
sectScat = m_scatter([Q1(2), Q2(2)], [Q1(1), Q2(1)], ...
    'MarkerFaceColor', lineCol, 'MarkerEdgeColor', lineCol, 'LineWidth', 6); 
m_grid('box','fancy','linestyle','-','gridcolor','w','backcolor',[.3 .75 1]);

% get usable stations
stinbounds = stainfo.slats<=max(lalim) & stainfo.slats>=min(lalim) &...
             stainfo.slons<=max(lolim) & stainfo.slons>=min(lolim);

% find stas with good fits overall and good fit to Sp data;
gdstas = zeros(stainfo.nstas,1);
for is = 1:stainfo.nstas 
    
    % check in bounds
    if stinbounds(is)==0, continue; end
    clear sdtyp
    sta = stainfo.stas{is}; 
    nwk = stainfo.nwk {is}; 
    
    resdir = sprintf('%s%s_%s_dat%.0f/%s',proj.STAinversions,sta,nwk,generation,STAMP);
    fdir = [resdir, '/final_model.mat']; 
    gdstas(is) =  exist(fdir, 'file');
    
    if ~gdstas(is); continue; end; % can't load par if it doesn't exist. Just do continue. 
    par=load([resdir,'/par.mat']); par=par.par; 
    disp(par.inv)
    gdstas(is) = (par.inv.niter>=8000) && (par.inv.nchains>=5); % Don't plot results if we didn't run the inversion with enough chains or iterations. Might have been test runs...
end
gdstas = find(gdstas);

Ngd = length(gdstas);


lolim = [min(stainfo.slons(gdstas)),max(stainfo.slons(gdstas))] + [-1 1];
% make colourmap
cmap2gmtcpt(lolim(2),lolim(1),flipud(parula),'parula_lolim.cpt');

%% Load CCP
addpath(paths.models_seismic); 
nccp = 100; 
ccpla = linspace(Q1(1),Q2(1),nccp);
ccplo = linspace(Q1(2),Q2(2),nccp);
[RFz,zz] = load_CCP_RFz([ccpla(:),ccplo(:)]);

%% prep output station file
fid = fopen(ostafile,'w');

%% prep figure
fig = figure(56); clf; 
set(fig,'pos',[-1204 344 1092 620]); 
set(gcf, 'color', 'white');
ax1 = axes; hold on
ax2 = axes; hold on
ax3 = axes; hold on
ax4 = axes; hold on

  

x0 = 0.08; xw = 0.82;
ax1Height = 0.45 ; 
set(ax1,'pos',[x0 0.36 xw ax1Height]);
set(ax2,'pos',[x0 0.22 xw 0.11]);
set(ax3,'pos',[x0 0.08 xw 0.11]);
set(ax4,'pos',[x0 0.85 xw 0.11], 'XTick', []); %!%!


% Topography
[topox, topoy, topoz] = get_z_etopo1(...
    lolim(1)-.5, lolim(2)+.5, ...
    lalim(1)-.5, lalim(2)+.5  );

% ==================  LOOP OVER STATIONS IN DB  ================== 
iKeepSta = 0; 
for ii = 1:Ngd
     
    is = gdstas(ii);
    sta = stainfo.stas{is};
    nwk = stainfo.nwk{is};
    fprintf(fid,'%s %8.4f %8.4f\n',sta,stainfo.slats(is),stainfo.slons(is)); 
    % get results directory
    resdir = sprintf('%s/%s_%s_dat%.0f/%s',proj.STAinversions,sta,nwk,generation,STAMP);
    
    % find position on section
    [d_perp(ii),d_par(ii)] = dist2line_geog( Q1,Q2,...
        [stainfo.slats(is),stainfo.slons(is)],0.1 );    

    if d_perp(ii) > offsecmax, continue; end
    
    % load final model and data
    load([resdir,'/par.mat'])
    load([resdir,'/posterior.mat'])
    load([resdir,'/final_model.mat'])
          
    
    %% plot vertical profiles by colour
 
    dh = 0.1; % half width 
    % round off VSav
    dVs = 0.03;
    VSuse = round_level(final_model.VSav,dVs);
    % colour for V profile
    Vclr = colour_get(VSuse,vlims(2),vlims(1),vcmp);
    % find layer boundaries
    zzz = mean(final_model.Z(find(diff(VSuse)~=0) + [0 1]),2);
    Nz = length(zzz)+1;
    % make fill objects
    XVSfill = d_par(ii) + [-dh dh dh -dh -dh]'*ones(1,Nz);
    YVSfill = zeros(5,Nz);
    % clr
    clear CVSfill
    for ic = 1:3
        CVSfill(1,:,ic) = [Vclr(diff(VSuse)~=0,ic);Vclr(end,ic)]';
    end
    % row 1
    YVSfill(:,1) = [0 0 zzz(1) zzz(1) 0]';
    % int rows
    for iz = 2:Nz-1
        YVSfill(:,iz) = [zzz(iz-1) zzz(iz-1) zzz(iz) zzz(iz) zzz(iz-1)]';
    end
    % row end
    YVSfill(:,end) = [zzz(end) zzz(end) final_model.Z(end) final_model.Z(end) zzz(end)]';
    
    %% make fill
    hp(ii) = patch(ax1,XVSfill,YVSfill,CVSfill,'linestyle','none','Facealpha',0.7); hold on

	%% plot moho
    hm(ii) = plot(ax1,d_par(ii)+[-dh dh],final_model.Zd(2).mu*[1 1],'m','linewidth',4);hold on
    
    plt_sed = plot(ax4,d_par(ii)+[-dh dh],final_model.Zd(1).mu*[1 1],'m','linewidth',4);hold on

    % plot NVG
    try
        [nvg_z(ii,1),nvg_w(ii,1),nvg_av(ii,1)] = model_NVG_info(final_model);
    end

    %% store VpVs
    VpVs_cr(ii,1) = final_model.vpvsav;
    VpVs_sig2_cr(ii,:) = final_model.vpvssig2';
    
	%% store radial anis (crust)
    Xi_cr(ii,1) = final_model.xicrav;
    Xi_sig2_cr(ii,:) = final_model.xicrsig2';

end
fclose(fid); % close file with station locations/names

insection = d_perp<=offsecmax;

% plot goodstas in section on map
figure(mapFigNum); 
staScat = m_plot(stainfo.slons(gdstas(insection)),stainfo.slats(gdstas(insection)),...
    '^','linewidth',0.01, 'markerSize', 14, ...
    'MarkerFaceColor', [0,0,0], 'MarkerEdgeColor', [0,0,0]); 
figure(fig);

%% plot VpVs
errorbar(ax2,d_par(insection),VpVs_cr(insection),VpVs_sig2_cr(insection,1)-VpVs_cr(insection),VpVs_sig2_cr(insection,2)-VpVs_cr(insection),'o')
scatter(ax2,d_par(insection),VpVs_cr(insection),150,VpVs_cr(insection),'filled')

%% plot Xi
errorbar(ax3,d_par(insection),Xi_cr(insection),Xi_sig2_cr(insection,1)-Xi_cr(insection),Xi_sig2_cr(insection,2)-Xi_cr(insection),'o')
h_xi = scatter(ax3,d_par(insection),Xi_cr(insection),150,Xi_cr(insection),'filled');

%% plot NVG
for ii = 1:Ngd
    try
    errorbar(ax1,d_par(ii),nvg_z(ii),nvg_w(ii)/2,'k','linewidth',1.5);
    plot(ax1,d_par(ii),nvg_z(ii),'db','linewidth',2,'Markerfacecolor','k');
    end
end

%% cbar
ax1Pos = get(ax1,'pos'); 
axC = axes(fig,'pos',ax1Pos,'visible','off');
hcb  = colorbar(axC); caxis(axC,vlims); colormap(axC,vcmp);
set(hcb,'pos',[ax1Pos(1)+0.01 + ax1Pos(3), ax1Pos(2) 0.017 ax1Pos(4)],'linewidth',2)
ylabel(hcb, '\textbf{V$_S$ (km/s)}','fontsize',16,'interpreter','latex'); 

%% Axes 

% compute degrees lon along profile
loprof = Q1(2) + (Q2(2)-Q1(2))*get(ax2,'xtick')/distance(Q1(1),Q1(2),Q2(1),Q2(2));

set(ax1,'fontsize',16,'ylim',[-20 260],'xlim',[0 ceil(max(d_par))+0.5],...
    'ydir','reverse','xticklabel','',...
    'color','none','box','on','layer','top','linewidth',1.8);

set(ax2,'fontsize',16,'ylim',[1.62 1.9],'xlim',[0 ceil(max(d_par))+0.5],...
    'color','none','box','on','layer','top','linewidth',1.8,...
    'xticklabel',[],'ytick',[1.65:.1:1.85]);
caxis(ax2,[1.55,1.95]);colormap(ax2,spring)

set(ax3,'fontsize',16,'ylim',[0.95 1.12],'xlim',[0 ceil(max(d_par))+0.5],...
    'color','none','box','on','layer','top','linewidth',1.8,...
    'xticklabels',round_level(loprof,0.1));

set(ax4, 'fontsize', 16, 'ylim', [0, 2.5], 'xlim', [0 ceil(max(d_par))+0.5],...
    'ydir','reverse','xticklabel','',...
    'color','none','box','on','layer','top','linewidth',1.8);

caxis(ax3,[0.88,1.12]);colormap(ax3,flipud(spring))

%
ylabel(ax3,'$\mathbf{\xi}$ \textbf{crust}','fontsize',20,'interpreter','latex')
ylabel(ax4,'\textbf{Sed (km)}' ,'fontsize',20,'interp','latex','fontweight','bold'); 
ylabel(ax2,{'\textbf{Crustal}','$\mathbf{V}p/\mathbf{V}s$'},'fontsize',20,'interp','latex','fontweight','bold')
ylabel(ax1,'\textbf{Depth (km)}','fontsize',20,'interp','latex','fontweight','bold')
xlabel(ax3,'\textbf{Longitude}','fontsize',20,'interp','latex','fontweight','bold')

% brb2022.06.06. Get lat (slt) and lon (sln) of points along our
% cross-sections line. These are used for interpolating topography. Note:
% this requires the mapping matlab package. If you dont have it, need to
% find another way to get topography along cross-sections line. 
% Make Topo axis to join with the model axis. 
ax1Topo = copyobj(ax1, gcf);
axes(ax1Topo); cla; 

ax1Topo.Visible = 'off'; % Only show what I plot here. Not labels, etc. 
ax1.    Visible = 'on' ; 

gcarc = distance(Q1, Q2); 
azline= azimuth (Q1, Q2); 
[latout_is_Q2, lonout_is_Q2] = reckon(Q1(1), Q1(2), gcarc, azline); % As a test, these outputs should be Q2. 
[slt, sln] = reckon(Q1(1), Q1(2), linspace(0,gcarc,300), azline); % As a test, these outputs should be Q2. 
slt = slt'; % Lats along our line for topo
sln = sln'; % lons along our line for topo. 
topo = griddata(topox, topoy, topoz', sln, slt); % Topo as a function of longitude and latitude. 
[topo_perp, topo_par] = dist2line_geog( Q1,Q2,...
        [slt, sln],0.1 ); % Get topo distance, in degrees. Seems like that's what unit Zach is using as horizontal unit? 
topo = -topo./1000
topo_exaggerate = 13; 
topo(topo<0) = topo(topo<0)*topo_exaggerate;
plot(ax1Topo, topo_par, topo, ...
    'linewidth', 2, 'color', [54, 163, 0]./256); 
linkaxes([ax1, ax1Topo]); 
axes(ax1); 

% In case we have any negative depth yticks, corresponding to topography, just
% get rid of those yticks. Most people don't explicitly put topography
% ontheir plots anyway. 
ytickarray = yticks(); 
if any(ytickarray<0); 
    set(gca, 'ytick', ytickarray(ytickarray>=0) ); 
end

% How much exageration is there? 
figure(56); 
axes(ax1); 
figPos = get(gcf, 'pos') ; 
axPos  = get(gca, 'pos'); 
aspectFig = figPos(4) / figPos(3); % Aspect in this case is vertical over horizontal. 
aspectAx  = axPos (4) / axPos (3);
aspectDisplay = aspectFig * aspectAx * 0.44/0.465; % Multiply the two aspects together to get total aspect. The scaler at the end is the ratio of physical measurements on my screen with a ruler versus the aspectDisplay variable with no correction. THey are close. This is an emperical correction to handle things like labels.  
aspectData = diff(ylim) / (diff(xlim) * 111); 
verticalExag = aspectDisplay / aspectData; 
fprintf('\nVertical exaggeration = %1.2f\n', verticalExag);

%% save
if ifsave
    exportgraphics(figure(56),[ofile1 '.pdf']);
    exportgraphics(figure(mapFigNum), [ofile1 '_map.pdf'], ...
        'BackgroundColor','none') ;  %exportgraphics(figure(mapFigNum), '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/figures/xsect/Xsect_thingy.pdf')
else
    pause
end

%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% Subfunctions
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************
%% ***********************************************************************************************************************************

function vertical_profiles(ax,final_model,variable,titlestr,clr)
% Vertical 1D profiles
% available "variable" values are 'VS','VP','rho'
variables = {'VS','VP','rho'};
xlims = [[3.7,4.9];[5.9 9.1];[2.6 3.7]];
ylim = [20 250];
iv = find(strcmp(variables,variable));
xlims = xlims(iv,:);

fill(ax,[final_model.([variable,'sig1'])(:,1);...
              flipud(final_model.([variable,'sig1'])(:,2))],...
              [final_model.Z;flipud(final_model.Z)],'-',...
              'Linewidth',1.5,'Facecolor',clr,'Edgecolor',[0.6 0.6 0.6],'facealpha',0.4,'edgealpha',0.5);
% plot(ax,final_model.([variable,'av']),final_model.Z,'-r','Linewidth',2);
% plot(ax,final_model.([variable,'sig2']),final_model.Z,'-','color',[0.4 0.4 0.4],'Linewidth',1);

set(ax,'ydir','reverse','fontsize',15,'ytick',[0:25:max(final_model.Z)],'ylim',ylim,'xlim',xlims(iv,:),...
    'color','none','box','on','linewidth',1.8,'xaxislocation','top');

% figN_add(titlestr,ax,0.1,-0.05,18);

xlabel(ax,[variable,' (km/s)'],'fontsize',17,'fontweight','bold')
ylabel(ax,'Depth (km)','fontsize',17,'fontweight','bold') 

% moho
Zmoh(1) = final_model.Zd(2).mu;
Zmoh(2) = final_model.Zd(2).std;
plot(ax,xlims(1,1)+[0 1]*diff(xlims(1,:)),Zmoh(1)*[1 1],'--','linewidth',2,'color',clr)
% text(ax,xlims(1,1)+0.15,Zmoh(1)+5,sprintf('%.1f',Zmoh(1)),...
%     'fontsize',13,'interpreter','tex')    
end

% crustal anisotropy histograms

function crust_anis_hist(ax,posterior,clr)
X = midpts(linspace(0.90,1.1,20));
No = hist(posterior.xicrust,X)/posterior.Nstored;
bar(ax,X,No','facecolor',clr,'facealpha',0.2,'edgecolor',[0.3 0.3 0.3],'BarWidth',0.8,'LineWidth',0.8);
set(ax,'fontsize',15,'xlim',[0.90,1.1],'ylim',[0 0.5],'ytick',[],...
    'color','none','box','on','layer','top','linewidth',1.8);
xlabel(ax,'Crustal \xi','fontsize',15,'interp','tex','fontweight','bold')
end

% crustal Vp/Vs histograms
function crust_vpvs_hist(ax,posterior,clr)
X = midpts(linspace(1.6,1.9001,40));
No = hist(posterior.vpvs(:,end),X)/posterior.Nstored;
bar(ax,X,No','facecolor',clr,'facealpha',0.2,'edgecolor',[0.3 0.3 0.3],'BarWidth',0.8,'LineWidth',0.8);
set(ax,'fontsize',15,'xlim',[1.6,1.9],'ylim',[0 0.3],'ytick',[],...
    'color','none','box','on','layer','top','linewidth',1.8);
xlabel(ax,'Crustal Vp/Vs','fontsize',15,'interp','tex','fontweight','bold')
end

% Moho histograms
function moho_hist(ax,posterior,clr)
X = midpts(linspace(25,65,40));
No = hist(posterior.zmoh(:,end),X)/posterior.Nstored;
bar(ax,X,No','facecolor',clr,'facealpha',0.2,'edgecolor',[0.3 0.3 0.3],'BarWidth',0.8,'LineWidth',0.8);
set(ax,'fontsize',15,'xlim',[27,61],'ylim',[0 0.18],'ytick',[],...
    'color','none','box','on','layer','top','linewidth',1.8);
xlabel(ax,'Moho depth (km)','fontsize',15,'interp','tex','fontweight','bold')
end

% plot map of NW US
function inset_map_NWUS(ax)
    lalim = [40 49];
    lolim = [-127 -85];
    axes(ax);
    m_proj('Gall-peters','lon',lolim,'lat',lalim)
    m_coast;
    m_grid('linestyle','none','tickdir','out','linewidth',3,'fontsize',14,'layer','top','xtick',[-125:10:-80]);
    [CS,CH]=m_etopo2('contourf',[[-5000:200:0],[1,10,50,100:200:3000]],'edgecolor','none');
    colormap(ax,1 - (1-[m_colmap('water',27);m_colmap('bland',18)]).^1);
    caxis(ax,[-5000 3000])
end

% plot great circle between end points
function plot_greatcircle(ax,Q1,Q2)
    dr = 0.1;
    [qgc,qaz] = distance(Q1(1),Q1(2),Q2(1),Q2(2));
    rr = unique([0:dr:qgc,qgc])';
    Nq = length(rr);

    QQ = zeros(Nq,2);
    for iq = 1:Nq
        [QQ(iq,1), QQ(iq,2)] = reckon(Q1(1),Q1(2),rr(iq), qaz);
    end
    m_plot(QQ(:,2),QQ(:,1),'-r','linewidth',3)
    m_plot(QQ(1,2),QQ(1,1),'or','markersize',10,'markerfacecolor','r')
    m_plot(QQ(end,2),QQ(end,1),'or','markersize',10,'markerfacecolor','r')
end
