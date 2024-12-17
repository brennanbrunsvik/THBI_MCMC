function [ predata, par ] = b3_FORWARD_MODEL_BW( model,laymodel,par,...
    predataOrig,ID,ifplot,predataPrev )
% [ predata ] = b3_FORWARD_MODEL_BW( model,laymodel,par,predata,ID,ifplot )
% 
%   Do forward model to calculate predicted data.
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
%   predata - predicted body wave data inserted
%%
% An important component is the layerising of the model - conversion of
% continuous model into a bunch of layers, with coarseness partly
% determined by the minimum dVs in any layer (specified as an input). The
% layerised 1D model is also output from this function.

%% ===================  PREPARE DATA STRUCTURE  ===================

predata = predataOrig; 

for id = 1:length(par.inv.datatypes)
    pdtyps(id,:) = parse_dtype(par.inv.datatypes{id}); 
end

% [predata.PsRF.Vp_surf] = deal(mean([predata.PsRF.Vp_surf]));
% [predata.PsRF.Vs_surf] = deal(mean([predata.PsRF.Vs_surf]));


%% ===================  PS RFs FROM PROPAGATOR MATRIX  ====================

if any(strcmp(pdtyps(:,2),'Ps'))
    Psdat = par.inv.datatypes{find(strcmp(pdtyps(:,2),'Ps'),1,'first')};
    [ unique_rayps_P,irayps_P ] = rayp_vals( [predata.(Psdat).rayp] );
    for ir = 1:length(unique_rayps_P)
        rayp = unique_rayps_P(ir); % in s/deg
        samprate = unique([predata.(Psdat)(irayps_P==ir).samprate]);
        P_inc = rayp2inc(rayp,laymodel.Vp(end),6371-laymodel.zlayb(end));
        % check so we don't use too many layers - evaluate P-s time for 
        % conversion at each layer
        tps = (laymodel.zlayb-laymodel.zlayt).*( sqrt(laymodel.Vs.^-2 - rayp_sdeg2skm(rayp)^2) - sqrt(laymodel.Vp.^-2 - rayp_sdeg2skm(rayp)^2) );
        % use only layers where P-s arrival would not come in before window end
            n_before_twin = find( cumsum(tps) > (T_conv_max_Ps(par) + 3),1,'first');
            if ~isempty(n_before_twin)
                nuse = [1:n_before_twin]';
                fns = fieldnames(laymodel);
                laymodel_Puse = laymodel; 
                laymodel_Puse.nlay = length(nuse);
                for jj = 1:length(fns)
                    if length(laymodel.(fns{jj}))==1, continue; end
                    laymodel_Puse.(fns{jj}) = laymodel_Puse.(fns{jj})(nuse);
                end
                % set appropriate P_inc for the actual base
                P_inc = rayp2inc(rayp,laymodel_Puse.Vp(end),6371-laymodel_Puse.zlayb(end));
            else
                laymodel_Puse = laymodel;
            end        
        
        [predat_ps,tt_ps] = run_propmat_or_telewavesim(par.synth.propmat_or_telewavesim, laymodel_Puse,ID,'Ps',samprate, P_inc, rayp, par.forc.synthperiod,par.forc.nsamps);
        % pad with zeros
        tt_ps = [tt_ps(1) + [-1000:-1]'./samprate; tt_ps ;tt_ps(end) + [1:1000]'./samprate];
        predat_ps = [zeros(1000,3);predat_ps;zeros(1000,3)];
        %correct corrdinate order
        predat_ps_ZRT = predat_ps(:,[3,1,2]); % in Z,R,T
        if strcmp(par.forc.PSVorZR,'PSV')
            clear predat_ps_PSV;
            % convert to P, SV
            [predat_ps_PSV(:,1),predat_ps_PSV(:,2)] = ...
                Rotate_XZ_to_PSV(predat_ps_ZRT(:,2),-predat_ps_ZRT(:,1),...
                mean([predata.(Psdat).Vp_surf]),mean([predata.(Psdat).Vs_surf]),...
                rayp_sdeg2skm(rayp,laymodel.zlayb(end)));
        elseif strcmp(par.forc.PSVorZR,'ZR')
            % keep as ZR (but kill T; Z positive UP)
            predat_ps_PSV = predat_ps_ZRT(:,[1,2]);         
        end
        predat_ps_PSV = predat_ps_PSV./maxab(predat_ps_PSV(:,1)); % normalise on parental max, make positive
        tt_ps_Par = mean(tt_ps(predat_ps_PSV(:,1)==max(predat_ps_PSV(:,1))));% estimate main P-wave arrival time from first big upswing
        tt_ps = tt_ps - tt_ps_Par;
        tt_ps = round_level(tt_ps,0.001);

        Ps_widewind = [-10 50];
        inwind = (tt_ps >= Ps_widewind(1)) & (tt_ps < Ps_widewind(2)); 
        % crop
        predat_ps_PSV = predat_ps_PSV(inwind,:);
        tt_ps = tt_ps(inwind);
        if ~any(inwind)
            tt_ps = []; predat_ps_PSV = nan; % NO GOOD DATA
        else
            % taper
            predat_ps_PSV = flat_hanning_win(tt_ps,predat_ps_PSV,Ps_widewind(1),Ps_widewind(2),1); % 1s taper
            % normalise to unit energy
            % normf_ps = predat_ps(:,1)'*predat_ps(:,1) + predat_ps(:,2)'*predat_ps(:,2) + predat_ps(:,3)'*predat_ps(:,3);
            % predat_ps = predat_ps/sqrt(normf_ps);'
        end
        
        % -----------------  PUT INTO DATA STRUCTURE  -----------------
        inds = find(irayps_P==ir);
        for iir = 1:length(inds)
            predata.(Psdat)(inds(iir),1).PSV=predat_ps_PSV; 
            predata.(Psdat)(inds(iir),1).tt=tt_ps;
            predata.(Psdat)(inds(iir),1).nsamp = length(predata.(Psdat)(inds(iir)).PSV);
        end
    end
end

%% ===================  SP RFs FROM PROPAGATOR MATRIX  ====================
if any(strcmp(pdtyps(:,2),'Sp'))    
if any(~strcmp(pdtyps(strcmp(pdtyps(:,2),'Sp'),3),'ccp'))
    Spdat = par.inv.datatypes{find(strcmp(pdtyps(:,2),'Sp'),1,'first')};
    [ unique_rayps_S,irayps_S ] = rayp_vals( [predata.(Spdat).rayp] );
    for ir = 1:length(unique_rayps_S)
        rayp = unique_rayps_S(ir);
        samprate = unique([predata.(Spdat)(irayps_S==ir).samprate]);
        S_inc = rayp2inc(rayp,laymodel.Vs(end),6371-laymodel.zlayb(end));
        P_inc = rayp2inc(rayp,laymodel.Vp(end),6371-laymodel.zlayb(end));
        % check if S inhomogeneous
        if isreal(asind(laymodel.Vs*sind(S_inc)./laymodel.Vs(end))) % 
            
            % find layers where S to P conversion will not go inhomogeneous
            Play_incs = asind(laymodel.Vp*sind(P_inc)./laymodel.Vp(end));
            if any(~isreal(Play_incs))
                nimagplay = [1:find(imag(Play_incs),1,'first')-1];
                fns = fieldnames(laymodel);
                laymodel_Suse = laymodel; 
                laymodel_Suse.nlay = length(nimagplay);
                for jj = 1:length(fns)
                    if length(laymodel.(fns{jj}))==1, continue; end
                    laymodel_Suse.(fns{jj}) = laymodel_Suse.(fns{jj})(nimagplay);
                end
                % set appropriate S_inc for the actual base
                S_inc = rayp2inc(rayp,laymodel_Suse.Vs(end),6371-laymodel_Suse.zlayb(end));
            else
                laymodel_Suse = laymodel;
            end
            [predat_sp,tt_sp] = run_propmat_or_telewavesim(par.synth.propmat_or_telewavesim,laymodel_Suse,ID,'Sp',samprate, S_inc, rayp, par.forc.synthperiod,par.forc.nsamps);
            % pad with zeros
            tt_sp = [tt_sp(1) + [-1000:-1]'./samprate; tt_sp ;tt_sp(end) + [1:1000]'./samprate];
            predat_sp = [zeros(1000,3);predat_sp;zeros(1000,3)];
            %correct corrdinate order
            predat_sp_ZRT = predat_sp(:,[3,1,2]); % in Z,R,T
            if strcmp(par.forc.PSVorZR,'PSV')
                clear predat_sp_PSV;
                % convert to P, SV
                [predat_sp_PSV(:,1),predat_sp_PSV(:,2)] = ...
                    Rotate_XZ_to_PSV(predat_sp_ZRT(:,2),-predat_sp_ZRT(:,1),...
                    mean([predata.(Spdat).Vp_surf]),mean([predata.(Spdat).Vs_surf]),...
                    rayp_sdeg2skm(rayp,laymodel_Suse.zlayb(end)));
            elseif strcmp(par.forc.PSVorZR,'ZR')
                % keep as ZR (but kill T; Z positive UP)
                predat_sp_PSV = predat_sp_ZRT(:,[1,2]);         
            end
            predat_sp_PSV = predat_sp_PSV./maxab(predat_sp_PSV(:,2)); % normalise on parental max, make positive
            tt_sp_Sar = mean(tt_sp(predat_sp_PSV(:,2)==max(predat_sp_PSV(:,2)))); % estimate main S-wave arrival time from first big upswing
            tt_sp = tt_sp - tt_sp_Sar;
            tt_sp = round_level(tt_sp,0.001);

            Sp_widewind = [-50 10];
            inwind = (tt_sp >= Sp_widewind(1)) & (tt_sp < Sp_widewind(2)); 
            % crop
            predat_sp_PSV = predat_sp_PSV(inwind,:);
            tt_sp = tt_sp(inwind);

            if ~any(inwind)
                tt_sp = []; predat_sp_PSV = nan; % NO GOOD DATA
            else
                % taper
                predat_sp_PSV = flat_hanning_win(tt_sp,predat_sp_PSV,Sp_widewind(1),Sp_widewind(2),1); % 1s taper
                % normalise to unit energy
                % normf_sp = predat_sp(:,1)'*predat_sp(:,1) + predat_sp(:,2)'*predat_sp(:,2) + predat_sp(:,3)'*predat_sp(:,3);
                % predat_sp = predat_sp/sqrt(normf_sp);
            end
        else
            tt_sp = NaN; predat_sp_PSV = NaN;    
        end
        
% -----------------  PUT INTO DATA STRUCTURE  -----------------
        inds = find(irayps_S==ir);
        for iir = 1:length(inds)
            predata.(Spdat)(inds(iir),1).PSV=predat_sp_PSV; 
            predata.(Spdat)(inds(iir),1).tt=tt_sp;
            predata.(Spdat)(inds(iir),1).nsamp = length(predata.(Spdat)(inds(iir)).PSV);
        end
    end
end % Sp can't only be ccp
end

%% ===================  HK-stack: put in values  ====================
if any(strcmp(pdtyps(:,1),'HKstack'))
    [predata, par] = hk_forward_model(par, model, ...
        predata, pdtyps, predataPrev); % Put HK forward modelling code into it's own file, for repeatability with later code. 
end


%% distribute data for different processing (e.g. _lo, _cms, CCP)
for idt = 1:length(par.inv.datatypes)
    dtype = par.inv.datatypes{idt}; 
    pdt = parse_dtype( dtype ); 
    % for BW case
    if strcmp(pdt{1},'BW') && (~strcmp(pdt{3},'def') || ~strcmp(pdt{4},'def'))
        if any(strcmp(par.inv.datatypes,['BW_',pdt{2}])) % only if there IS a standard!
            predata.(dtype) = predata.([pdt{1},'_',pdt{2}]); % insert standard BW if needed
        end
    end
    % for RF case - basically identical
    if strcmp(pdt{1},'RF') && (~strcmp(pdt{3},'def') || ~strcmp(pdt{4},'def')) && ~strcmp(pdt{3},'ccp')
        if any(strcmp(par.inv.datatypes,['RF_',pdt{2}])) % only if there IS a standard!
            predata.(dtype) = predata.([pdt{1},'_',pdt{2}]); % insert standard BW if needed
        end
    end
    
end






%% ifplot....

if ifplot
    figure(2); clf, hold on
    comps = {'VERTICAL','RADIAL','TRANSVERSE'}; 
    for ic = 1:2
        
        subplot(3,2,2*ic-1)
        plot(tt_ps,predat_ps_PSV(:,ic)./max(max(predat_ps_PSV)),'Linewidth',2)
        xlim(par.datprocess.Ps.Twin.def);
        ylim([-1 1])
        ylabel(comps{ic},'fontsize',19,'fontweight','bold')
        if ic == 1, title('Ps','fontsize',22,'fontweight','bold'), end
        
        subplot(3,2,2*ic)
        plot(tt_sp,predat_sp_PSV(:,ic)./max(max(predat_sp_PSV)),'Linewidth',2)
        xlim(par.datprocess.Sp.Twin.def);
        ylim([-1 1])
        if ic == 1, title('Sp','fontsize',22,'fontweight','bold'), end
    end
    set(gcf,'position',[780         282        1058         823]);
end % on ifplot



end

