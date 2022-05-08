% Set path manually depending on what you are trying to plot I guess. 
% brb2022.03.21 This file is made in z1_SYNTH....m
rfStruct = load('/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/SYNTHETICS/inversion_results/teststa_testnwk_dat0/examplerun/tru_receiver_functions.mat');
rf = rfStruct.rfSave; 

rf.tt_ps < rf.ps_twin.def(2); % ptime. IDK exactly what this means. 

figure(1); clf; hold on; 
set(gcf, 'pos', [303 950 473 275], 'color', 'white'); 
box on; 
xlim([-2, 32]); 
ylim([1.5 * min(rf.trudat_ps_PSV(:,2)), 1.5 * max(rf.trudat_ps_PSV(:,2))])
xlabel('t (s)'); 
lw = 2; 
title('Synthetic Ps receiver function'); 

plot(rf.tt_ps, rf.trudat_ps_PSV(:,1), 'LineWidth', lw / 2,...
    'DisplayName', 'Z', 'Color', 'blue'); 
plot(rf.tt_ps, rf.trudat_ps_PSV(:,2), 'LineWidth', lw    ,...
    'DisplayName', 'R', 'Color', 'k'   ); 
lgd = legend(); 
title(lgd, 'Component'); 



%%% Text. Made using Matlab GUI
figure1=gcf; 
annotation(figure1,'textbox',...
    [0.290456941858738 0.791666700174259 0.0455116279069765 0.0727272727272718],...
    'String',{'Ps'},...
    'LineStyle','none',...
    'FontName','Helvetica Neue',...
    'FontAngle','italic',...
    'FitBoxToText','off');

% Create textbox
annotation(figure1,'textbox',...
    [0.578475509952743 0.732638900323872 0.0455116279069778 0.0727272727272713],...
    'String','PpPs',...
    'LineStyle','none',...
    'FontName','Helvetica Neue',...
    'FontAngle','italic',...
    'FitBoxToText','off');

% Create textbox
annotation(figure1,'textbox',...
    [0.772024109680887 0.277777625350113 0.0455116279069774 0.0727272727272708],...
    'String',{'PpSs + PsPs'},...
    'LineStyle','none',...
    'FontName','Helvetica Neue',...
    'FontAngle','italic',...
    'FitBoxToText','off');
%%%

exportgraphics(gcf, 'synth_receiver_function.pdf'); 