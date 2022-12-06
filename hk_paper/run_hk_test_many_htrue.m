run_hk_test_setup_bs; % This does some obnoxious setup. % Run it then comment it out if you want to save some time. 

%% HK tests, analysis, starts here. 
xi_a = [0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.15]'; 
xi_true = 0.85; 
if ~ any(xi_a == xi_true); error('Pick xi true that is in xi_a'); end
i_xi_true = find(xi_a == xi_true); 
nxi = length(xi_a); 

% ztrue_a = [15, 25, 35, 45, 55 ]; 
ztrue_a = 25:5:55; 
% ktrue_a = [1.75];

nzi = length(ztrue_a); 
% nki = length(ktrue_a); 


% par.datprocess.kNum = 101; 
% par.datprocess.hNum = 100; 
par.datprocess.kNum = 501; 
par.datprocess.hNum = 500; 
warning('Less hk resolution right now')

% Exi_all = zeros(nzi, nki, nxi, ) % Nope, not worth it

Exi_all = cell([length(xi_a), 1]); 
E00_all = cell([length(xi_a), 1]); 

t_pred_xi_best_all = zeros(length(xi_a), 3); 
t_pred_xi_noan_all = zeros(length(xi_a), 3); 

hmax_all_noan = zeros(nxi,1); 
kmax_all_noan = zeros(nxi,1); 

rf_all = cell(length(xi_a),1); 

herr = zeros(nxi, 1); 
kerr = zeros(nxi, 1); 

dhedxi = zeros(length(ztrue_a),1); % Change in h error with respect to xi. 
dkedxi = zeros(length(ztrue_a),1); 

global TRUEmodel %Unfortunately this was already used as a global model
each_model = {}; 

for iztrue  = 1:length(ztrue_a); 
for ixi = 1:length(xi_a);  
%     for ixi = i_xi_true;  

    fprintf('Do something about xi_true.\n')

%     ztrue = 45; 
%     ktrue = 1.75; 
    xitruei = xi_a(ixi);
    ztruei = ztrue_a(iztrue); 

    par.mod.crust.hmin = 5; 
    [trudata,par] = a2_LOAD_DATA_hk_test(par, 'nwk', nwk, 'sta', sta, ...
        'xi_crust', xitruei , 'h_crust',  ztruei);

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
    warning('I think I had k and h indicies backwards in the above line')
    kmax_noan = K(ikmax); 
    hmax_noan = H(ihmax); 
    herr(ixi) = hmax_noan - ztrue; 
    kerr(ixi) = kmax_noan - ktrue; 

    [ikmax, ihmax] = find(Exi == max(Exi ,[], 'all')); 
    kmax_best = K(ikmax); 
    hmax_best = H(ihmax); 
%     herr(ixi) = hmax_noan - ztrue; 
%     kerr(ixi) = kmax_noan - ktrue; 
    
    t_pred_xi_best  = zeros(1, 3); % Get the times from anisotropic stack at true parameters
    t_pred_xi_noan  = zeros(1, 3); % Get the times from ISOTROPIC stack at true parameters. 
%     t_pred_xi_noan = zeros(1, 3);
    for it = 1:length(t_pred_xi_best); 
        t_pred_xi_best(1, it) = interpn(H, K, ...
            reshape(t_predxi(it,:,:), size(t_predxi,2), size(t_predxi,3)) , ...
            ztrue, ktrue, 'cubic'); 
        t_pred_xi_noan(1, it) = interpn(H, K, ...
            reshape(t_pred00(it,:,:), size(t_predxi,2), size(t_predxi,3)) , ...
            ztrue, ktrue, 'cubic'); 
    end
    t_pred_xi_best_all(ixi, :) = t_pred_xi_best; 
    t_pred_xi_noan_all(ixi, :) = t_pred_xi_noan; 
    
    rf_all{ixi} = waves.rf; %  + ixi; 
    Exi_all{ixi} = Exi; 
    E00_all{ixi} = E00; 
    hmax_all_noan(ixi) = hmax_noan; 
    kmax_all_noan(ixi) = kmax_noan; 

    hmax_all_best(ixi) = hmax_best; 
    kmax_all_best(ixi) = kmax_best; 

    %%% How much error in the non-anisotropic HK stack? 
%     interp2(H, K, E00, hmax, kmax)
    %%%
end

% % % % Take simple slop between two points. 
% % % xi_small = 0.9; 
% % % xi_large = 1.1; 
% % % is_xi_small = xi_a == xi_small; 
% % % is_xi_large = xi_a == xi_large; 
% % % dhedxi(iztrue) = (herr(is_xi_large) - herr(is_xi_small)) / (xi_a(is_xi_large) - xi_a(is_xi_small)) /100 ; 
% % % dkedxi(iztrue) = (kerr(is_xi_large) - kerr(is_xi_small)) / (xi_a(is_xi_large) - xi_a(is_xi_small)) /100 ; 
% % % 
% % % figure(1); clf; hold on; 
% % % subplot(2,1,1); hold on; ylabel('H err'); 
% % % scatter(xi_a, herr)
% % % subplot(2,1,2); hold on; ylabel('K err');
% % % scatter(xi_a, kerr)
% % % xlabel('\xi')

% Alternate way of getting slope. Solve 2nd order polynomial, taking the
% 1st derivative slope at xi = 0. 
dxip = (xi_a - 1) * 100; 
dhp  = herr ./ ztrue * 100 ;
dkp  = kerr ./ ktrue * 100 ; 
[hpol, hpfun] = polyfit( dxip , dhp , 2); 
[kpol, kpfun] = polyfit( dxip , dkp , 2); 

xlin_plot = linspace(min(dxip), max(dxip) ); 
g0 = find(xlin_plot>=0); % where is xlin_plot greater than 0?
g0 = g0(1); 
l0 = g0-1; % where is xlin_plot just less than 0? Doesn't matter if these two are offset by an integer or two. 

dhpre = polyval(hpol, xlin_plot'); 
dkpre = polyval(kpol, xlin_plot'); 
dh_slope = hpol(end-1); 
dk_slope = kpol(end-1); 
% dh_slope = (dhpre(g0) - dhpre(l0)) / (xlin_plot(g0) - xlin_plot(l0) ); 
% dk_slope = (dkpre(g0) - dkpre(l0)) / (xlin_plot(g0) - xlin_plot(l0) ); 


dhedxi(iztrue) = dh_slope; 
dkedxi(iztrue) = dk_slope; 

figure(2); clf; hold on; set(gcf,'pos',[2024 1360 318 206]); 
grid on; box on; set(gca, 'LineWidth', 1.5); 
ylabel('Percent change'); 
title(sprintf('H = %1.2f km',ztrue), 'fontweight', 'normal'); 
scatter(dxip, dhp)
hnd_h = plot(xlin_plot, dhpre, 'DisplayName',sprintf(...
    'dH/d\\xi, slope = %1.3f',dh_slope)); 
% subplot(2,1,2); hold on; ylabel('K err');
scatter(dxip, dkp)
hnd_k = plot(xlin_plot, dkpre, 'DisplayName',...
    sprintf('dK/d\\xi, slope = %1.3f',dk_slope) ); 
xlabel('d\xi (%)')
legend([hnd_h, hnd_k]); 

end

% dhedxi = dhedxi .^ (-1); 
% dkedxi = dkedxi .^ (-1); 

% % % dhedxi = dhedxi ./ ztrue_a' * 100; 
% % % dkedxi = dkedxi ./ ktrue * 100; % Don't have vector of k true yet

% % % %%
% % % figure(501); clf; hold on; 
% % % set(gcf, 'pos', [-826 509 291 168]); 
% % % set(gcf, 'pos', [2051 776 291 168]); 
% % % box on; 
% % % grid on; 
% % % set(gca,'LineWidth', 1.5); 
% % % xlabel('H_{true}')
% % % title('Sensitivity to \xi versus H', 'FontWeight','normal'); 
% % % 
% % % % yyaxis left; 
% % % ylabel('%dH_{sol} / %\xi_{true}'); 
% % % plot(ztrue_a, dhedxi, 'o')
% % % plot(ztrue_a, dhedxi, '-')
% % % 
% % % % yyaxis right; 
% % % ylabel('%dK_{sol} / %\xi_{true}'); 
% % % plot(ztrue_a, dkedxi, 'o'); 
% % % plot(ztrue_a, dkedxi, '-'); 
% % % 
% % % exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'rf_error_with_H', 'pdf'), 'ContentType', 'vector'); 
%%
figure(501); clf; hold on; 
set(gcf, 'pos', [-826 509 291 168]); 
set(gcf, 'pos', [2051 776 291 168]); 
box on; 
grid on; 
set(gca,'LineWidth', 1.5); 
xlabel('H_{true}')
title('Sensitivity to \xi versus H', 'FontWeight','normal'); 

% ylabel('%dH_{sol} / %\xi_{true}'); 
hnd_h = scatter(ztrue_a, dhedxi, 'filled', 'DisplayName', '%dH_{sol} / %d\xi_{true}')
% plot(ztrue_a, dhedxi, '-')

% ylabel('%dK_{sol} / %\xi_{true}'); 
hnd_k = scatter(ztrue_a, dkedxi, 'filled', 'DisplayName', '%dK_{sol} / %d\xi_{true}'); 
% plot(ztrue_a, dkedxi, '-'); 

legend([hnd_h, hnd_k], 'Location', 'best'); 

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'rf_error_with_H', 'pdf'), 'ContentType', 'vector'); 
 
%%
figure(201); clf; hold on; 
subplot(1,2,1); hold on; 
set(gca,'ydir', 'reverse'); 
contourf(K, H, Exi_all{i_xi_true}', 30, 'EdgeAlpha', 0.1); 
ylim([5, 55]); 
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
fhand_norm = @(inval)inval ./ max(max(inval)); % Return normalized inval 

figure(301); clf; hold on; set(gcf, 'pos', [-1089 329 364 218]); 
subplot(1,1,1); hold on; 
set(gca,'ydir', 'reverse', 'LineWidth', 1.5);
grid on; 
box on; 
xlabel('\kappa'); 
ylabel('H (km)'); 
title('H-\kappa stack ignoring \xi', 'fontweight', 'normal'); 
% contourf(K, H, Exi_all{i_xi_true}', 30, 'EdgeAlpha', 0.1); 

plt_ylim = [40, 50]; 
plt_xlim = [1.6, 1.9]; 
ylim(plt_ylim); 
xlim(plt_xlim); 

% plot([ktrue, ktrue], plt_ylim + [-1, 1])
hnd_true = scatter(ktrue, ztrue, 200, [252, 3, 252]./256, 'pentagram', 'filled', ...
    'LineWidth', 1, 'MarkerEdgeColor', 'k',... 
    'DisplayName', 'True'); 

lvl_cnt = [0.7, 0.95]; 
LW = 1; 
[~,hnd_xistart] = contour(K, H, fhand_norm(E00_all{1      }'),...
    lvl_cnt, 'r', 'LineWidth', LW, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(1      ) ),...
    'LineStyle','--'); 
[~,hnd_xi1    ] = contour(K, H, fhand_norm(E00_all{end    }'),...
    lvl_cnt, 'b', 'LineWidth', LW, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(end    ) ),...
    'LineStyle','--'); 
[~,hnd_xiend  ] = contour(K, H, fhand_norm(E00_all{xi_a==1}'),...
    lvl_cnt, 'k', 'LineWidth', LW*1.5, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(xi_a==1) ) ); 


% scatter(kmax_all_noan, hmax_all_noan, size_scat, 'red', 'filled'); 
% scatter(kmax_all_noan(i_xi_true), hmax_all_noan(i_xi_true), size_scat*2, 'red', 'diamond', 'filled'); 
% plot(kmax_all_noan, hmax_all_noan, 'red', 'LineWidth', 1.);
% text(kmax_all_noan+0.005, hmax_all_noan - 0.75, string(xi_a) )


legend([hnd_xistart, hnd_xiend, hnd_xi1, hnd_true], 'Location', 'best'); 

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'multiple_contour', 'pdf'), 'ContentType', 'vector'); 


%%
figure(302); clf; hold on; set(gcf, 'pos', [-1089 329 364 218]); 
subplot(1,1,1); hold on; 
set(gca,'ydir', 'reverse', 'LineWidth', 1.5);
grid on; 
box on; 
xlabel('\kappa'); 
ylabel('H (km)'); 
title('H-\kappa stack \xi corrected', 'fontweight', 'normal'); 
% contourf(K, H, Exi_all{i_xi_true}', 30, 'EdgeAlpha', 0.1); 

plt_ylim = [40, 50]; 
plt_xlim = [1.6, 1.9]; 
ylim(plt_ylim); 
xlim(plt_xlim); 

% plot([ktrue, ktrue], plt_ylim + [-1, 1])
hnd_true = scatter(ktrue, ztrue, 200, [252, 3, 252]./256, 'pentagram', 'filled', ...
    'LineWidth', 1, 'MarkerEdgeColor', 'k',... 
    'DisplayName', 'True'); 

lvl_cnt = [0.7, 0.95]; 
LW = 1; 
[~,hnd_xistart] = contour(K, H, fhand_norm(Exi_all{1      }'),...
    lvl_cnt, 'r', 'LineWidth', LW, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(1      ) ),...
    'LineStyle','--'); 
[~,hnd_xi1    ] = contour(K, H, fhand_norm(Exi_all{end    }'),...
    lvl_cnt, 'b', 'LineWidth', LW, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(end    ) ),...
    'LineStyle','--'); 
[~,hnd_xiend  ] = contour(K, H, fhand_norm(Exi_all{xi_a==1}'),...
    lvl_cnt, 'k', 'LineWidth', LW*1.5, ...
    'DisplayName', sprintf('\\xi = %1.2f', xi_a(xi_a==1) ) ); 


% scatter(kmax_all_noan, hmax_all_noan, size_scat, 'red', 'filled'); 
% scatter(kmax_all_noan(i_xi_true), hmax_all_noan(i_xi_true), size_scat*2, 'red', 'diamond', 'filled'); 
% plot(kmax_all_noan, hmax_all_noan, 'red', 'LineWidth', 1.);
% text(kmax_all_noan+0.005, hmax_all_noan - 0.75, string(xi_a) )


% legend([hnd_xistart, hnd_xiend, hnd_xi1, hnd_true], 'Location', 'best'); 

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'multiple_contour_hkcor', 'pdf'), 'ContentType', 'vector'); 



%%
figure(202); clf; hold on; 
set(gcf, 'pos', [1060 564 445 235]); 
set(gca, 'LineWidth', 1.5, 'XGrid', 'on', 'XMinorTick', 'on'); box on; %grid on; 
xlabel('Time (s)'); 
title('Phase timing', 'FontWeight','normal'); 
set(gca, 'YTick', []); 
xlim([-3, 30])
yshift_const = 0.075; 

for ixi = 1:nxi
    yshift = ixi * yshift_const; 
    rf = rf_all{ixi}; 

    t_pred_xi_best = t_pred_xi_best_all(ixi,:)'; 
    t_pred_xi_noan = t_pred_xi_noan_all(ixi,:)'; 

    hnd_t_xi = scatter(...
        t_pred_xi_best', yshift + interp1(waves.tt, rf, t_pred_xi_best, 'cubic'),...
        40, 'blue', 'filled') % If using true parameters and anisotropic stack
    hnd_t_00 = scatter(...
        t_pred_xi_noan', yshift + interp1(waves.tt, rf, t_pred_xi_noan, 'cubic'),...
        40, 'red', 'filled') % If using true parameters and isotropic stack
%     hnd_t_xi = scatter(...
%         t_pred_xi_best', yshift + interp1(waves.tt, rf, t_pred_xi_best, 'cubic'),...
%         100, '+blue') % If using true parameters and anisotropic stack
%     hnd_t_00 = scatter(...
%         t_pred_xi_noan', yshift + interp1(waves.tt, rf, t_pred_xi_noan, 'cubic'),...
%         100, '+red') % If using true parameters and isotropic stack
    hnd_rf = plot(waves.tt, yshift+rf, 'k', 'linewidth', 1.5);

    if ixi == nxi; 
        xilabel = '\xi = '; 
    else; 
        xilabel = "      "; 
    end

    text(1, yshift + yshift_const * .5, sprintf('%s%1.2f', xilabel, xi_a(ixi) ) )

end

% scatter(0, -2*yshift_const, 0.00001); 
ylim([-2*yshift_const, yshift_const * (nxi+2.5)])
lgd = legend([hnd_rf, hnd_t_00, hnd_t_xi], ...
    'Receiver function', 't ignore \xi', 't with \xi'); 
set(lgd, 'Orientation', 'horizontal', 'Location', 'south'); 

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'rftiming', 'pdf'), 'ContentType', 'vector'); 

%%
figure(203); clf; hold on; 
set(gcf, 'pos', [-826 509 291 168]); 
box on; 
grid on; 
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

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'rf_error', 'pdf'), 'ContentType', 'vector'); 

%% Try to plot objective function, or something like that. 

%ztrue, ktrue, xi_true

% For this, need to make E that is nxi x nh x nk, (or something like that).
Eob = zeros(nxi, par.datprocess.kNum, par.datprocess.hNum); 
for ixi = 1:nxi; 
    Eob(ixi,:,:) = Exi_all{ixi}; 
end

ind_closest = @(H, ztrue)find(abs(H - ztrue) == min(abs(H - ztrue))); % Index closest to H in ztrue. Obviously don't have to use H and ztrue. 

ztruei = ind_closest(H, ztrue); 
ktruei = ind_closest(K, ktrue); 
xitruei= ind_closest(xi_a, xi_true); 

Etmp = Eob(:, ktruei, :); 

flatar = @(M)reshape(M,[],1); % flat array

ylim_man = [-0.01, 0.11]; 
figure(401); clf; hold on; box on; grid on; set(gca,'LineWidth', 1.5); 
tiledlayout(3,1,'TileSpacing','compact'); 

nexttile(), hold on, ylim(ylim_man), box on, grid on; 
xlabel('Moho depth (km)'); xlim([25, 60]); 
plot( H, flatar(Eob(xitruei, ktruei, :)) ,...
    'k'); 

nexttile(), hold on, ylim(ylim_man), box on, grid on; 
xlabel('Vp/Vs'); % xlim([25, 60]); 
ylabel('E')
plot( K, Eob(xitruei, :, ztruei) ,...
    'k'); 

nexttile(), hold on, ylim(ylim_man), box on, grid on; 
xlabel('\xi'); 
plot( xi_a, Eob(:,ktruei, ztruei) ,...
    'k'); 

%%
zylim = [0, 60]; 
model_cor = each_model{i_xi_true}; %model we did the correction to 
LW = 1.5; 

figure(204); clf; hold on; 
set(gcf, 'pos', [-800 377 317 240]); 
tiledlayout(1,2,'TileSpacing','compact'); 
% sgtitle('Model'); 

nexttile(); hold on; set(gca, 'LineWidth', LW, 'YDir', 'reverse'); box on; ylim(zylim); 
xlabel('Velocity (km/s)'); 
grid on; 
plot(model_cor.VS, model_cor.z, 'DisplayName', 'VS', 'LineWidth', LW); 
plot(model_cor.VP, model_cor.z, 'DisplayName', 'Vp', 'LineWidth', LW); 
legend(); 
xlim([min(model_cor.VS-0.75), max(model_cor.VP+0.75)])

ylabel('Depth (km)'); 

nexttile(); hold on; set(gca, 'LineWidth', LW, 'YDir', 'reverse'); box on; ylim(zylim); 
xlabel('% Anisotropy'); 
grid on; 
set(gca, 'yticklabel', []); 
plot(   model_cor.Sanis, model_cor.z, 'DisplayName', '+ \xi', ...
    'LineWidth', LW, 'LineStyle','-'); 
plot( - model_cor.Panis, model_cor.z, 'DisplayName', '- \phi', ...
    'LineWidth', LW*1.5, 'LineStyle','--'); 
% xticks = string(get(gca, 'XTicklabel')) ; 
% xticks(xticks~="0") = ""; 
% set(gca, 'xticklabels', xticks); 
xlim([-18, 0 + 3]); 
legend(); 

exportgraphics(gcf, fhand_figname(ztrue, ktrue, 'synth_model', 'pdf'), 'ContentType', 'vector'); 
