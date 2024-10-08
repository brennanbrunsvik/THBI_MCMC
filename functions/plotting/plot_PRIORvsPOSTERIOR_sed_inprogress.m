function plot_PRIORvsPOSTERIOR(prior,posterior,par,ifsave,ofile)
% plot_PRIORvsPOSTERIOR(prior,posterior,par,ifsave,ofile)
%   
% function to compare prior and posterior models w/ some relevant metrics

if nargin<4 || isempty(ifsave)
    ifsave = 0; % default is not to save
end
if nargin<5 || isempty(ofile)
    ofile = 'figs/priorvsposterior_fig.pdf';
end
 
%% Set up plot
figure(19), clf, set(gcf,'pos',[100 100 1440 796]);
htile = tiledlayout(3,8,'TileSpacing','compact'); 
cls = get(groot,'defaultAxesColorOrder');

%% Moho depth
nexttile(1, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(par.mod.sed.hmin+par.mod.crust.hmin,par.mod.sed.hmax+par.mod.crust.hmax,20));
No = hist(posterior.zmoh,X)/posterior.Nstored;
Ni = hist(prior.zmoh,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[par.mod.sed.hmin+par.mod.crust.hmin par.mod.sed.hmax+par.mod.crust.hmax],'ylim',[0 axlim(gca,4)])
title('Moho depth (km)','fontsize',16, 'FontWeight', 'normal')

if par.inv.synthTest; 
    global TRUEmodel
    zmoh = TRUEmodel.zmoh; 
    yplt = get(gca, 'ylim'); 
    plot([zmoh, zmoh], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

%% Sed
% subplot(341), cla, hold on
nexttile(3); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(0,par.mod.sed.hmax,40));
No = hist(posterior.zsed,X)/posterior.Nstored;
Ni = hist(prior.zsed,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[0 par.mod.sed.hmax],'ylim',[0 axlim(gca,4)])
title('Sediment depth (km)','fontsize',16, 'FontWeight', 'normal')
if par.inv.synthTest; 
    global TRUEmodel
    zsed = TRUEmodel.zsed; 
    yplt = get(gca, 'ylim'); 
    plot([zsed, zsed], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

% subplot(341), cla, hold on
nexttile(4); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(0,0.5,40));
No = hist(posterior.zsed,X)/posterior.Nstored;
Ni = hist(prior.zsed,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[0 max(X)],'ylim',[0 axlim(gca,4)])
title('Sediment depth (km)','fontsize',16, 'FontWeight', 'normal')
if par.inv.synthTest; 
    global TRUEmodel
    zsed = TRUEmodel.zsed; 
    yplt = get(gca, 'ylim'); 
    plot([zsed, zsed], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

%% V crust bottom (commented out top)
% subplot(342), cla, hold on
% X = midpts(linspace(par.mod.crust.vsmin,par.mod.crust.vsmax,20));
% No = hist(posterior.VScrusttop,X)/posterior.Nstored;
% Ni = hist(prior.VScrusttop,X)/prior.Nstored;
% bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
% bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
% set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
%         'xlim',[par.mod.crust.vsmin,par.mod.crust.vsmax],'ylim',[0 axlim(gca,4)])
% title('Vs crust top (km/s)','fontsize',16)

nexttile(9, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(par.mod.crust.vsmin,par.mod.crust.vsmax,20));
No = hist(posterior.VScrustbot,X)/posterior.Nstored;
Ni = hist(prior.VScrustbot,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[par.mod.crust.vsmin,par.mod.crust.vsmax],'ylim',[0 axlim(gca,4)])
title('Vs crust bot (km/s)','fontsize',16, 'FontWeight', 'normal')

if par.inv.synthTest; 
    vsBot = TRUEmodel.crustmparm.VS_sp(end); % brb2022.02.18 Not 100% sure this is the right value
    yplt = get(gca, 'ylim'); 
    plot([vsBot, vsBot], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

%% Moho dVs
nexttile(17, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(0,30,20));
No = hist(posterior.fdVSmoh,X)/posterior.Nstored;
Ni = hist(prior.fdVSmoh,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'ylim',[0 axlim(gca,4)])
title('fractional dVs at Moho (%)','fontsize',16, 'fontweight', 'normal')

if par.inv.synthTest; 
    vscTemp = TRUEmodel.crustmparm.VS_sp(end); 
    vsmTemp = TRUEmodel.mantmparm.VS_sp(1); 
    fracChange = (vsmTemp - vscTemp) / vscTemp * 100; 
    yplt = get(gca, 'ylim'); 
    plot([fracChange, fracChange], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

%% H-K value
nexttile(23, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
plot(prior.vpvs,prior.zmoh,'.k','markersize',2)
plot(posterior.vpvs,posterior.zmoh,'.r','markersize',2)
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
     'xlim',[par.mod.crust.vpvsmin,par.mod.crust.vpvsmax],...
     'ylim',[par.mod.sed.hmin+par.mod.crust.hmin par.mod.sed.hmax+par.mod.crust.hmax])
title('H-K comparison','fontsize',16, 'FontWeight', 'normal')


%% Crustal Vp/Vs
nexttile(15, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(par.mod.crust.vpvsmin,par.mod.crust.vpvsmax,20));
No = hist(posterior.vpvs,X)/posterior.Nstored;
Ni = hist(prior.vpvs,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[par.mod.crust.vpvsmin,par.mod.crust.vpvsmax],'ylim',[0 axlim(gca,4)]) 
title('Crust Vp/Vs ratio','fontsize',16, 'FontWeight', 'normal')

if par.inv.synthTest; 
    vpvsTemp = TRUEmodel.crustmparm.vpvs; 
    yplt = get(gca, 'ylim'); 
    plot([vpvsTemp, vpvsTemp], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
end

%% Crust radial anisotropy
if par.mod.crust.ximin~=par.mod.crust.ximax
    nexttile(7, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
    X = midpts(linspace(par.mod.crust.ximin,par.mod.crust.ximax,20));
    No = hist(posterior.xicrust,X)/posterior.Nstored;
    Ni = hist(prior.cxi,X)/prior.Nstored;
    bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
    bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
    set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
            'xlim',[par.mod.crust.ximin,par.mod.crust.ximax],'ylim',[0 axlim(gca,4)]) 
    title('Crust Xi value','fontsize',16, 'FontWeight', 'normal')
    
    if par.inv.synthTest; 
        xiTemp = TRUEmodel.crustmparm.xi; 
        yplt = get(gca, 'ylim'); 
        plot([xiTemp, xiTemp], [yplt(1), yplt(2)], 'b', 'LineWidth', 2); 
    end
end

%% Mantle radial anisotropy
if par.mod.mantle.ximin~=par.mod.mantle.ximax
nexttile(5, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(par.mod.mantle.ximin,par.mod.mantle.ximax,20));
No = hist(posterior.ximant,X)/posterior.Nstored;
Ni = hist(prior.mxi,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[par.mod.mantle.ximin,par.mod.mantle.ximax],'ylim',[0 axlim(gca,4)]) 
title('Mantle Xi value','fontsize',16, 'FontWeight', 'normal')
end

%% Width of mantle NVG
% find depth indices with negative grad
nvgg = -0.004;
% posterior
Lnvg_post = zeros(posterior.Nstored,1);
for ii = 1:posterior.Nstored
    nvind = find([diff(posterior.VSmantle(ii,:)')./diff(posterior.zatdep)<nvgg;0] & posterior.zatdep>posterior.zmoh(ii));
    if isempty(nvind), Lnvg_post(ii)=nan; continue; end
    a = diff(nvind);
    b = find([a;inf]>1);
    c = diff([0;b]);% length of sequences with nvgs
    di1 = cumsum(c); % end points of sequences with nvgs
    di0 = di1-c+1; % start points of sequences with nvgs
    nvindm = [nvind(di0(c==max(c))):nvind(di1(c==max(c)))]';
    Lnvg_post(ii) = diff(posterior.zatdep(nvindm([1,end])));
end
% prior
Lnvg_pri = zeros(prior.Nstored,1);
for ii = 1:prior.Nstored
    nvind = find([diff(prior.VSmantle(ii,:)')./diff(prior.zatdep)<nvgg;0] & prior.zatdep>prior.zmoh(ii));
    if isempty(nvind), Lnvg_pri(ii)=nan; continue; end
    a = diff(nvind);
    b = find([a;inf]>1);
    c = diff([0;b]);% length of sequences with nvgs
    di1 = cumsum(c); % end points of sequences with nvgs
    di0 = di1-c+1; % start points of sequences with nvgs
    nvindm = [nvind(di0(c==max(c))):nvind(di1(c==max(c)))]';
    Lnvg_pri(ii) = diff(prior.zatdep(nvindm([1,end])));
end

nexttile(13, [1,2]); cla; hold on; box on; set(gca, 'linewidth', 1.5); 
X = midpts(linspace(0,200,40));
No = hist(Lnvg_post,X)/posterior.Nstored;
Ni = hist(Lnvg_pri,X)/prior.Nstored;
bar(X,No','facecolor',[0.9 0.1 0.1],'edgecolor','none','BarWidth',1);
bar(X,Ni','facecolor','none','edgecolor',[0.2 0.2 0.2],'BarWidth',1,'LineWidth',1.5);
set(gca,'fontsize',14,'box','on','linewidth',1.5,'layer','top',...
        'xlim',[0,200],'ylim',[0 axlim(gca,4)]) 
title('max NVG width (km)','fontsize',16, 'FontWeight', 'normal')

%% title
htit = title_custom([par.data.stadeets.sta,' ',par.data.stadeets.nwk],0.05,'fontweight','bold','fontsize',25);

if ifsave
    save2pdf(19,ofile,'/');
end

end

