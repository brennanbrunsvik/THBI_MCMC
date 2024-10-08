function [ predata ,laymodel ] = b3__INIT_PREDATA( model,par,trudata,ifplot )
% [ predata ,laymodel ] = b3__INIT_PREDATA( model,par,trudata,ifplot )
% 
%   Wipe trudata to make predata, and layerize model
% 
% INPUTS
%   model   - model structure
%   Kbase   - structure with kernel model, depth kernels, and its phase vels
%   par     - parameters structure
%   predata - data structure with all datatypes 
%   ID      - unique ID for the propmat script to avoid overwriting files
%             if running in parallel.
%   ifplot  - flag with option to plot (1) or not (0)
% 
% OUTPUTS
%   predata - structure identical to input data structure, but with
%             BLANK data, rather than observed data
%%
% An important component is the layerising of the model - conversion of
% continuous model into a bunch of layers, with coarseness partly
% determined by the minimum dVs in any layer (specified as an input). The
% layerised 1D model is also output from this function.

%% ===================  PREPARE DATA STRUCTURE  ===================

for id = 1:length(par.inv.datatypes)
    pdtyps(id,:) = parse_dtype(par.inv.datatypes{id}); 
end

% [predata.PsRF.Vp_surf] = deal(mean([predata.PsRF.Vp_surf]));
% [predata.PsRF.Vs_surf] = deal(mean([predata.PsRF.Vs_surf]));

%% ===================  ERASE INPUT DATA TO MAKE SURE  ===================
predata = trudata;

indtypes = fieldnames(trudata); % look at all dtypes in predata
for idt = 1:length(indtypes)
    pdt = parse_dtype(indtypes{idt}); % parse data type
    if any(strcmp({'BW','RF'},pdt{1}))
        for irp = 1:length(predata.(indtypes{idt})) % loop over all ray parameters if several
            predata.(indtypes{idt})(irp).PSV(:) = nan; % set to nan
        end
    elseif strcmp({'SW'},pdt{1}) 
        predata.(indtypes{idt}).(pdt{3})(:) = nan; % set to nan
    end
end

%% ===================  LAYERISE PROFILE  ===================
if isfield(par.datprocess.CCP, 'layerise_version') && strcmp(par.datprocess.CCP.layerise_version, 'no_sed'); % Remove sediment for TESTING propmat. 
    [zlayt,zlayb,Vslay,... % brb2022.07.06 Version that prevents us from needing to make assumptions here about xi, rho, eta, ...
        Vplay,rholay,xilay,philay] = ...
        layerise_test_sediment_sp_ccp(model.z,model.VS,par.forc.mindV,0,...
        model.VP, model.rho, ...
        model.Sanis./100+1,model.Panis./100+1); 
else
    [zlayt,zlayb,Vslay,... % brb2022.07.06 Version that prevents us from needing to make assumptions here about xi, rho, eta, ...
        Vplay,rholay,xilay,philay] = ...
        layerise(model.z,model.VS,par.forc.mindV,0,...
        model.VP, model.rho, ...
        model.Sanis./100+1,model.Panis./100+1); 
end
nlay = length(Vslay);
etalay = ones(nlay,1); % eta anisotropy TODO get eta from model. eta is not in model right now, so can't yet. 

laymodel = struct('zlayt',zlayt,'zlayb',zlayb,'Vs',Vslay,'Vp',Vplay,'rho',rholay,'nlay',nlay,'xi',xilay,'phi',philay,'eta',etalay);
if any(isnan(laymodel.rho))
    error('NaN densities')
end


ifplot = false; if ifplot; warning('Setting ifplot = true'); end; 
if ifplot
    figure(1); clf, hold on; set(gcf, 'color', 'white'); 
    box on; 
    grid on; 
    xlabel('V'); 
    ylabel('Z (km)'); 
    title('Layering of model'); 
    plot(model.VS,model.z,'-ko')
    plot(model.VP,model.z,'-ko')
    zlayp = reshape([laymodel.zlayt';laymodel.zlayb'],2*laymodel.nlay,1);
    vslayp = reshape([laymodel.Vs';laymodel.Vs'],2*laymodel.nlay,1);
    vplayp = reshape([laymodel.Vp';laymodel.Vp'],2*laymodel.nlay,1);
    plot(vslayp,zlayp,'-ro')
    plot(vplayp,zlayp,'-ro')
    set(gca,'ydir','reverse','ylim',[0, max(model.z)],'xlim',[0.9*min(model.VS) 1.1*max(model.VP)])
    set(gcf,'pos',[77 1 685 586]);
    text(6, 150, sprintf('N lay = %1.0f',laymodel.nlay), 'FontSize', 16); 
%     exportgraphics(gcf, sprintf('%s/layerize.pdf',par.res.resdir))
end



end

