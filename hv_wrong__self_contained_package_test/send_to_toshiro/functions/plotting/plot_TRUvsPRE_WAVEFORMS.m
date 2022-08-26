function axs = plot_TRUvsPRE_WAVEFORMS( trudata,predata,posterior,par,ifsave,ofile,ifnorm)
%plot_TRUvsPRE_WAVEFORMS( trudata,predata,ifsave,ofile )
%   
% function to plot predicted and true seismograms (Vertical and Radial)
% Assumes date in 3-column ZRT matrices with equal sample rate 

if nargin < 5 || isempty(ifsave)
    ifsave=false;
end

if nargin < 6 || isempty(ofile)
    ofile='true_vs_predicted_data';
end

if nargin < 7 || isempty(ifnorm)
    ifnorm=true;
end

boxLineWidth = 1.75; 
titleSize = 20; 
xlims = [-3 31;-31 3]; %[P;S]

dtypes = fieldnames(predata);
dtypes(strcmp(dtypes,'SW')) = [];


figure(58),clf,set(gcf,'pos',[44 150 1500 1100])
ax1  = axes('position',[0.05 0.69 0.20 0.26]); hold on % Ps? 
ax2  = axes('position',[0.05 0.39 0.20 0.26]); hold on % Sp? 
ax3  = axes('position',[0.28 0.69 0.20 0.15 ]); hold on % Sp, HK present I guess. 
ax4  = axes('position',[0.28 0.39 0.20 0.15 ]); hold on % Sp, parent pulse. 
ax5  = axes('position',[0.51 0.69 0.20 0.26]); hold on
ax6  = axes('position',[0.51 0.39 0.20 0.26]); hold on
ax7  = axes('position',[0.72 0.69 0.20 0.26]); hold on
ax8  = axes('position',[0.72 0.39 0.20 0.26]); hold on

ax9  = axes('position',[0.05 0.05 0.24 0.21]); hold on % Rayleigh 
ax10 = axes('position',[0.36 0.05 0.24 0.21]); hold on % Love
ax11 = axes('position',[0.67 0.05 0.24 0.21]); hold on % HV

axs=[ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9,ax10,ax11];
for iaxs = [1:length(axs)]; 
    set(axs(iaxs), 'Box', 'on'); 
    set(axs(iaxs), 'linewidth', boxLineWidth); 
end


if any(strcmp(fieldnames(trudata),'HKstack_P'))
%     ax12 = axes('pos',[axpos(ax2,[1,2,3]) sum(axpos(ax1,[2,4]))-axpos(ax2,2)]); hold on % HK
    ax12  = axes('position',[0.05 0.39 0.20 0.3]); hold on % Ps? 
    delete([ax1,ax2]);
    set(ax12, 'Box', 'on'); 
    set(ax12, 'linewidth', boxLineWidth); 
    axs=[ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9,ax10,ax11];
end

% % % 
% % % for iaxs = [1:length(axs)]; 
% % %     set(axs(iaxs), 'Box', 'on'); 
% % %     set(axs(iaxs), 'linewidth', 2); 
% % % end

for id = 1:length(dtypes)
dtype = dtypes{id};
pdtyp = parse_dtype( dtype );
switch pdtyp{1}

%% SW
    case 'SW'
        switch pdtyp{2}
            case 'Ray', 
                ax = ax9; 
                ylabstr = 'Phase Velocity (km/s)';
                set(ax, 'xscale', 'log'); 
                xticks(ax, [5, 10, 20, 40, 60, 100, 180]); 
            case 'Lov', 
                ax = ax9; 
                ylabstr = 'Phase Velocity (km/s)';
            case 'HV',  
                ax = ax11;
                ylabstr = 'H/V ratio'; 
                errorbar(ax,trudata.(dtype).periods,trudata.(dtype).HVr,2*trudata.(dtype).sigma.*ones(size(trudata.(dtype).periods)),'k')
                set(ax, 'xscale', 'log'); 
                xticks(ax, [16, 20, 30, 40, 50, 70, 90]); 
        end
    hp(1) = plot(ax,trudata.(dtype).periods,trudata.(dtype).(pdtyp{3}),'ko-','linewidth',2,'markersize',10);
    hp(2) = plot(ax,predata.(dtype).periods,predata.(dtype).(pdtyp{3}),'r-x','linewidth',2,'markersize',10);
    hl = legend(ax,hp,'True','Pred','Location','SouthEast'); set(hl,'fontsize',15);
    set(ax,'fontsize',15)
    xlabel(ax,'Period (s)','fontsize',18)
    ylabel(ax,ylabstr,'fontsize',18)
    title(ax, 'Surface waves','fontsize',titleSize, 'fontweight', 'normal') ; 

%     title(ax,['SW-',pdtyp{2}],'fontsize',titleSize)

%% BWs
    case {'BW','RF'}
        axn = 0;
        switch pdtyp{2}
            case 'Ps', axn = axn+1; 
            case 'Sp', axn = axn+2;
        end
        if strcmp(pdtyp{4},'lo'),axn = axn+2; end



    xa1 = axs(2*axn-1); % order [5,7,1,3]
    xa2 = axs(2*axn); % order [6,8,2,4]
    if strcmp(pdtyp{2}(1),'P'), ps=1;xp=1;xsv=0.1;elseif strcmp(pdtyp{2}(1),'S'), ps=2;xp=0.1;xsv=1; end
    
    if ~isempty(predata.(dtype)) && ~isempty(predata.(dtype)(1).PSV)
        trunrm = zeros(length(trudata.(dtype)),1);
        prenrm = zeros(length(predata.(dtype)),1);
        for itr = 1:length(trudata.(dtype))
            if strcmp(pdtyp{3},'ccp')
                trudata.(dtype)(itr).tt = trudata.(dtype)(itr).zz;
                predata.(dtype)(itr).tt = predata.(dtype)(itr).zz;
            end
          
            
            if ifnorm
%                 trumax(itr) = max(abs(maxab(trudata.(dtype)(itr).PSV))); % get the max, to normalise trace
%                 premax = max(abs(maxab(predata.(dtype)(1).PSV))); % get the max, to normalise trace
                trunrm(itr) = norm(trudata.(dtype)(itr).PSV); % get the norm of the traces, to normalise power
                prenrm(itr) = norm(predata.(dtype)(itr).PSV); % get the norm of the traces, to normalise power
            else
                trunrm(itr) = 1;
                prenrm(itr) = 1;
            end
            plot(xa1,trudata.(dtype)(itr).tt,trudata.(dtype)(itr).PSV(:,1)./trunrm(itr),'k','linewidth',2.5)
            plot(xa1,predata.(dtype)(itr).tt,predata.(dtype)(itr).PSV(:,1)./prenrm(itr),'r','linewidth',1.5)
            plot(xa2,trudata.(dtype)(itr).tt,trudata.(dtype)(itr).PSV(:,2)./trunrm(itr),'k','linewidth',2.5)
            plot(xa2,predata.(dtype)(itr).tt,predata.(dtype)(itr).PSV(:,2)./prenrm(itr),'r','linewidth',1.5)
        end
        set(xa1,'xlim',xlims(ps,:),...
                'ylim',0.3*xp*[-1 1],...
                'fontsize',13)
        set(xa2,'xlim',xlims(ps,:),...
                'ylim',0.5*xsv*[-1 1],...
                'fontsize',13)
        title(xa1, regexprep(dtype,'_','-'),'fontsize',titleSize, 'fontweight', 'normal')
        xlabel(xa2, sprintf('Time from %s arrival',pdtyp{2}(1)),'fontsize',18)
        
        if strcmp(pdtyp{3},'ccp')
            set([xa1,xa2],'xlim',minmax(trudata.(dtype)(itr).zz')); 
            xlabel([xa1,xa2],'Depth of conversion (km)','fontsize',18)
        end
    
    end
    
%% HKstack        
    case {'HKstack'}
%         contourf(ax12,trudata.(dtype).K,trudata.(dtype).H,trudata.(dtype).Esum',30,'linestyle','none');
%         axis(ax12); 
%         box on;         
        [~,contH] = contourf(ax12,predata.(dtype).Kgrid,predata.(dtype).Hgrid,...
            predata.(dtype).Esum',30,'linestyle','none'); % Use final_predata to get the HK stack estimated with our velocity model. 
%         uistack(cntr,'top')

        cbar = colorbar(ax12,'eastoutside'); 
        set(cbar, 'fontsize', 12); 
%         cbar = colorbar(ax12,'south'); 
%         a =  cbar.Position;  %gets the positon and size of the color bar
%         set(cbar,'Position',[a(1)+.5 * a(3), a(2) .5 * a(3), a(4)],...
%             'fontsize', 12, ...
%             'linewidth', .01, ...
%             'color', [1 1 1]); % To change size

%         cmapSCM = 'imola'; 
%         load(sprintf('/Users/brennanbrunsvik/Documents/repositories/Peoples_codes/ScientificColourMaps7/%s/%s.mat',cmapSCM,cmapSCM)); % Temporary. Try out a new colormap. 
        try 
            colormap(viridis); 
        catch 
            warning('Missing colormap viridis. Should be in repositories somewhere. '); 
        end
%         colorbar(ax12,'south')
        
        plot(predata.HKstack_P.K,predata.HKstack_P.H,'ok','linewidth',2,...
            'markerfacecolor','r','markersize',7)
        
        title(ax12, regexprep(dtype,'_','-'),'fontsize',titleSize, 'fontweight', 'normal')
        xlabel(ax12, 'Vp/Vs ratio','fontsize',16)
        ylabel(ax12, 'Moho depth','fontsize',16)
        set(ax12,'ydir','reverse', 'linewidth', 4)
    
    
end
end

pause(0.001)


if ifsave
%     save2pdf(58,ofile,'/');
    exportgraphics(gcf, ofile, 'resolution', 300); 
end

% %% Ps
% if isfield(predata,'PsRF') && ~isempty(predata.PsRF(1).PSV)
% axes(ax5), hold on, set(gca,'fontsize',13,'xticklabel',[])
% axes(ax6), hold on, set(gca,'fontsize',13)
% for itr = 1:length(predata.PsRF)
% plot(trudata.PsRF.tt,trudata.PsRF.PSV(:,1),'k','linewidth',2.5), title('Ps','fontsize',22)
% plot(predata.PsRF.tt,predata.PsRF.PSV(:,1),'r','linewidth',1.5), 
% plot(trudata.PsRF.tt,trudata.PsRF.PSV(:,2),'k','linewidth',2.5), xlabel('Time from P arrival','fontsize',18)
% plot(predata.PsRF.tt,predata.PsRF.PSV(:,2),'r','linewidth',1.5), 
% end
% xlim(ax5,ps_xlims), ylim(ax5,1.1*max(abs(trudata.PsRF.PSV(:,1)))*[-1 1])
% xlim(ax6,ps_xlims), ylim(ax6,1.1*max(abs(trudata.PsRF.PSV(:,2)))*[-1 1])
% else
% delete(ax5),delete(ax6) 
% end
% 
% %% Sp
% if isfield(predata,'SpRF') && ~isempty(predata.SpRF.PSV)
% axes(ax7), hold on, set(gca,'fontsize',13,'xticklabel',[])
% plot(trudata.SpRF.tt,trudata.SpRF.PSV(:,1),'k','linewidth',2.5), title('Sp','fontsize',22)
% plot(predata.SpRF.tt,predata.SpRF.PSV(:,1),'r','linewidth',1.5),
% xlim(sp_xlims), ylim(1.1*max(abs(trudata.SpRF.PSV(:,1)))*[-1 1])
% axes(ax8), hold on, set(gca,'fontsize',13)
% plot(trudata.SpRF.tt,trudata.SpRF.PSV(:,2),'k','linewidth',2.5), xlabel('Time from S arrival','fontsize',18)
% plot(predata.SpRF.tt,predata.SpRF.PSV(:,2),'r','linewidth',1.5), 
% xlim(sp_xlims), ylim(1.1*max(abs(trudata.SpRF.PSV(:,2)))*[-1 1])
% else
% delete(ax7),delete(ax8) 
% end
% 
% 
% %% Ps_lo
% if isfield(predata,'PsRF_lo') && ~isempty(predata.PsRF_lo.PSV)
% axes(ax1), hold on, set(gca,'fontsize',13,'xticklabel',[])
% plot(trudata.PsRF_lo.tt,trudata.PsRF_lo.PSV(:,1),'k','linewidth',2.5), title('Ps-lo','fontsize',22)
% plot(predata.PsRF_lo.tt,predata.PsRF_lo.PSV(:,1),'r','linewidth',1.5), 
% xlim(ps_xlims), ylim(1.1*max(abs(trudata.PsRF_lo.PSV(:,1)))*[-1 1])
% axes(ax2), hold on, set(gca,'fontsize',13)
% plot(trudata.PsRF_lo.tt,trudata.PsRF_lo.PSV(:,2),'k','linewidth',2.5), xlabel('Time from P arrival','fontsize',18)
% plot(predata.PsRF_lo.tt,predata.PsRF_lo.PSV(:,2),'r','linewidth',1.5), 
% xlim(ps_xlims), ylim(1.1*max(abs(trudata.PsRF_lo.PSV(:,2)))*[-1 1])
% else
% delete(ax1),delete(ax2) 
% end
% 
% %% Sp_lo
% if isfield(predata,'SpRF_lo') && ~isempty(predata.SpRF_lo.PSV)
% axes(ax3), hold on, set(gca,'fontsize',13,'xticklabel',[])
% plot(trudata.SpRF_lo.tt,trudata.SpRF_lo.PSV(:,1),'k','linewidth',2.5), title('Sp-lo','fontsize',22)
% plot(predata.SpRF_lo.tt,predata.SpRF_lo.PSV(:,1),'r','linewidth',1.5),
% xlim(sp_xlims), ylim(1.1*max(abs(trudata.SpRF_lo.PSV(:,1)))*[-1 1])
% axes(ax4), hold on, set(gca,'fontsize',13)
% plot(trudata.SpRF_lo.tt,trudata.SpRF_lo.PSV(:,2),'k','linewidth',2.5), xlabel('Time from S arrival','fontsize',18)
% plot(predata.SpRF_lo.tt,predata.SpRF_lo.PSV(:,2),'r','linewidth',1.5), 
% xlim(sp_xlims), ylim(1.1*max(abs(trudata.SpRF_lo.PSV(:,2)))*[-1 1])
% else
% delete(ax3),delete(ax4) 
% end



% end

