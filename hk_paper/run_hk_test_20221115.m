% close all 
% clear all % Cannot clear all, because then we allways reset network_manual and station_manual below. 
%% Setup
run('../a0_STARTUP_BAYES.m')

proj = struct('name', 'SYNTHETICS'); % bb2021.08.04 changed from EXAMPLE because I don't have the example data files. %,'EXAMPLE');
paths = getPaths(); 
proj.STAinversions = paths.STAinversions; 
proj.dir = [fileparts(mfilename('fullpath')),'/'];
proj.STAinversions = paths.STAinversions; ; % [proj.dir,'inversion_results/'];
save([proj.dir,'project_details.mat'],'proj')

wd = pwd; addpath(wd);
cd(proj.dir);

%% specify details of this run
generation = 0; % generation of solution and data processing
gc = '';
BWclust = '';
STAMP = 'hk_paper_1';
onesta = '';

%% put parameters in place 
global run_params

% you can obviously adapt these (likely in some loop over stations etc.) to be appropriate for your dataset
run_params.projname = proj.name; % from above
run_params.gc = gc; % great circle distance of body wave data, if relevant
run_params.BWclust = BWclust; % cluster of BW data, if relevant
run_params.datN = generation; % processing iteration, if relevant
run_params.STAMP = STAMP; % NEED - some identifier for this inversion run
run_params.overwrite = 1; % do you want to overwrite previous results?
% % % if ~ (exist('network_manual', 'var') && exist('station_manual', 'var')) ; 
network_manual = 'testnwk'; 
station_manual = 'simple_layers_1'; %
fprintf('\nReseting to %s.%s\n',network_manual,station_manual)
% % % end
run_params.sta = station_manual; % name of station
run_params.nwk = network_manual; % name of network


global run_params
paths = getPaths(); 

projname = run_params.projname;
sta = run_params.sta;
nwk = run_params.nwk;
gc = run_params.gc;
BWclust = run_params.BWclust;
datN = run_params.datN;
STAMP = run_params.STAMP;
overwrite = run_params.overwrite;
global projdir TRUEmodel
projdir = [paths.THBIpath,'/',projname,'/'];
cd(projdir);
run([paths.THBIpath,'/a0_STARTUP_BAYES']);
load('project_details'); %TODO_STATION_NETWORK bb2021.11.12
addpath([proj.dir,'matguts/']);

%% PARMS
run parms/bayes_inv_parms
[par, inv] = update_bayes_inv_parms(par, STAMP); % Modify this function to make different tests. 


if strcmp(projname,'SYNTHETICS')
    par.stadeets = struct('sta',sta','nwk',nwk'); 
	noisesta = 'RSSD';
	noisenwk = 'IU';
	noisegcarcs = [73,38];
	noiseshape = 'real'; % 'white' or 'real'
	noiseup = 0.5; % factor to increase real noise
end

if strcmp(projname,'SYNTHETICS') || strcmp(projname,'LAB_tests')
    par.synth.noise_sta_deets = struct('datadir',['/Volumes/data/THBI/US/STAsinv/',noisesta,'_dat20/'],...
                         'sta',noisesta,'nwk',noisenwk,'gc',noisegcarcs,'noiseup',noiseup,'noiseshape',noiseshape);
end

par.inv.BWclust = BWclust;
ifsavedat = false;

%% get saving things ready
par.proj = proj;
avardir = sprintf('%s%s_%s_dat%.0f/',par.proj.STAinversions,sta,nwk,datN);
resdir = [avardir,STAMP];
if ~exist(resdir,'dir'), try mkdir(resdir); catch, error('Looks like no path to output directory - is it mounted?'); end, end

par.data = struct('stadeets',struct('sta',sta,'nwk',nwk,'Latitude',[],'Longitude',[]),...
                  'gc',gc,'datN',datN,'avardir',avardir);

par.res.STAMP = STAMP;
par.res.resdir= resdir;
par.res = orderfields(par.res,{'STAMP','resdir','zatdep'});

%% Get some directories ready. 
% Switch to execution folder, to make synthetic data. 
prev_dir = pwd(); 
cd(paths.ramDrive); % Execute everything from a folder in ram for major speedup. 
mkdir([nwk '_' sta]); cd([nwk '_' sta]); % Go to station specific folder to keep things clean . TODO just to cd once. 

%% HK tests, analysis, starts here. 
xi_a = [0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.15]'; 
xi_true = 0.85; 
xi_a = sort(unique([xi_a; xi_true])); 
nxi = length(xi_a); 
i_xi_true = find(xi_a == xi_true); 

Exi_all = cell([length(xi_a), 1]); 
% t_predxi_all = cell([length(xi_a), 1]); 
% t_pred00_all = cell([length(xi_a), 1]); 
t_pred_xi_best_all = zeros(length(xi_a), 3); 
hmax_all_noan = zeros(nxi,1); 
kmax_all_noan = zeros(nxi,1); 

rf_all = cell(length(xi_a),1); 

herr = zeros(nxi, 1); 
kerr = zeros(nxi, 1); 

global TRUEmodel %Unfortunately this was already used as a global model
each_model = {}; 

for ixi = 1:length(xi_a);  
%     for ixi = i_xi_true;  

    fprintf('Do something about xi_true.\n')

%     ztrue = 45; 
%     ktrue = 1.75; 
    xitruei = xi_a(ixi); 

    [trudata,par] = a2_LOAD_DATA_hk_test(par, 'nwk', nwk, 'sta', sta, ...
        'xi_crust', xitruei );

    each_model{ixi, 1} = TRUEmodel; 
    ztrue = TRUEmodel.zmoh; 
    ktrue = TRUEmodel.vpvs; 
    % plot_TRU_WAVEFORMS(trudata);

    
    
    H = trudata.HKstack_P.H;
    K = trudata.HKstack_P.K; 
    Exi = trudata.HKstack_P.Esum; 
    E00 = trudata.HKstack_P_noan.Esum; 
    waves = trudata.HKstack_P.waves; 
    t_predxi = trudata.HKstack_P.t_pred; 
    t_pred00 = trudata.HKstack_P_noan.t_pred; 

%     [Exi_max, iemax] = max(Exi, [], 'all'); %linear index. 
    [ikmax, ihmax] = find(E00 == max(E00 ,[], 'all')); 
    kmax_noan = K(ikmax); 
    hmax_noan = H(ihmax); 
    herr(ixi) = hmax_noan - ztrue; 
    kerr(ixi) = kmax_noan - ktrue; 

    [ikmax, ihmax] = find(Exi == max(Exi ,[], 'all')); 
    kmax_best = K(ikmax); 
    hmax_best = H(ihmax); 
%     herr(ixi) = hmax_noan - ztrue; 
%     kerr(ixi) = kmax_noan - ktrue; 
    
    t_pred_xi_true = zeros(1, 3); 
    t_pred_xi_best = zeros(1, 3); 
    t_pred_xi_noan = zeros(1, 3);
    for it = 1:length(t_pred_xi_best); 
        t_pred_xi_true(1, it) = interpn(H, K, ...
            reshape(t_predxi(it,:,:), size(t_predxi,2), size(t_predxi,3)) , ...
            ztrue, ktrue, 'cubic'); 
        t_pred_xi_best(1, it) = interpn(H, K, ...
            reshape(t_predxi(it,:,:), size(t_predxi,2), size(t_predxi,3)) , ...
            hmax_best, kmax_best, 'cubic'); 
    end
    t_pred_xi_best_all(ixi, :) = t_pred_xi_best; 
    rf_all{ixi} = waves.rf; %  + ixi; 
    Exi_all{ixi} = Exi; 
    hmax_all_noan(ixi) = hmax_noan; 
    kmax_all_noan(ixi) = kmax_noan; 

    hmax_all_best(ixi) = hmax_best; 
    kmax_all_best(ixi) = kmax_best; 

    %%% How much error in the non-anisotropic HK stack? 
    interp2(H, K, E00, hmax, kmax)
    %%%
end
 
%%
figure(201); clf; hold on; 
subplot(1,2,1); hold on; 
set(gca,'ydir', 'reverse'); 
contourf(K, H, Exi_all{i_xi_true}', 30, 'EdgeAlpha', 0.1); 
ylim([25, 55]); 
xlim([1.6, 1.9]); 

%%% Percentage contours
max_hk = max(Exi_all{i_xi_true},[], 'all'); 
contour(K, H, Exi_all{i_xi_true}', [0.68, 0.95].* max_hk, 'k', 'LineWidth',1); 
%%%

size_scat = 40; 

scatter(kmax_all_noan, hmax_all_noan, size_scat, 'red', 'filled'); 
scatter(kmax_all_noan(i_xi_true), hmax_all_noan(i_xi_true), size_scat*2, 'red', 'diamond', 'filled'); 
plot(kmax_all_noan, hmax_all_noan, 'red', 'LineWidth', 1.);

scatter(kmax_all_best, hmax_all_best, size_scat, 'blue', 'filled'); 
scatter(kmax_all_best(i_xi_true), hmax_all_best(i_xi_true), size_scat*2, 'blue', 'diamond', 'filled'); 
plot(kmax_all_best, hmax_all_best, 'blue', 'LineWidth', 1.);

% text(kmax_all_noan([1,nxi])+0.005, hmax_all_noan([1,nxi]) - 0.75, string(xi_a([1,nxi])) )
text(kmax_all_noan+0.005, hmax_all_noan - 0.75, string(xi_a) )


%%
figure(202); clf; hold on; 
set(gcf, 'pos', [1358 471 516 271]); 
set(gca, 'LineWidth', 1.5, 'XGrid', 'on', 'XMinorTick', 'on'); box on; %grid on; 
% subplot(1,2,2); hold on; 
xlim([-3, 30])

for ixi = 1:nxi
    yshift = ixi * 0.075; 
    rf = rf_all{ixi}; 
    t_pred_xi_best = t_pred_xi_best_all(ixi,:)'; 
%     if xi_a(ixi)~=1; 
        scatter(t_pred_xi_best', yshift+interp1(waves.tt, rf, t_pred_xi_best, 'cubic'),...
            'filled') % Not sure why not aligned well
        plot(waves.tt, yshift+rf, 'linewidth', 1.5); 
%     else
%         scatter(t_pred_xi_best', interp1(waves.tt, rf, t_pred_xi_best, 'cubic'),...
%             'k', 'filled'); % Not sure why not aligned well
%         plot(waves.tt, rf, 'k', 'LineWidth', 2); 
%     end

end


%%
figure(203); clf; hold on; 
set(gcf, 'pos', [-826 509 362 233]); 
box on; 
set(gca,'LineWidth', 1.5); 
xlabel('\xi true')

yyaxis left; 
ylabel('H error (km)'); 
plot(xi_a, herr, 'o')
plot(xi_a, herr, '-')

yyaxis right; 
ylabel('\kappa error')
plot(xi_a, kerr, 'o'); 
plot(xi_a, kerr, '-'); 



%%
zylim = [0, 60]; 
model_cor = each_model{i_xi_true}; %model we did the correction to 

figure(204); clf; hold on; 
set(gcf, 'pos', [1692 177 467 323]); 
tiledlayout(1,2,'TileSpacing','compact'); 
% sgtitle('Model'); 

nexttile(); hold on; set(gca, 'LineWidth', 1.5, 'YDir', 'reverse'); box on; ylim(zylim); 
xlabel('Velocity (km/s)'); 
plot(model_cor.VS, model_cor.z, 'DisplayName', 'VS'); 
plot(model_cor.VP, model_cor.z, 'DisplayName', 'Vp'); 
legend(); 

ylabel('Depth (km)'); 

nexttile(); hold on; set(gca, 'LineWidth', 1.5, 'YDir', 'reverse'); box on; ylim(zylim); 
xlabel('% Anisotropy'); 
plot(   model_cor.Sanis, model_cor.z, 'DisplayName', '+ \xi'); 
plot( - model_cor.Panis, model_cor.z, 'DisplayName', '- \psi'); 
legend(); 