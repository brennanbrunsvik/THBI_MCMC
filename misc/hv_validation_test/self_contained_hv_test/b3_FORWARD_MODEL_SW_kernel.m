function [ predata ] = b3_FORWARD_MODEL_SW_kernel( model,Kbase,par,predata )
%[ predata ] = b3_FORWARD_MODEL_SW_kernel( model,Kbase,par,predata )
% 
%   Do forward model to calculate predicted data.
% 
% INPUTS
%   model   - model structure
%   Kbase   - structure with kernel model, depth kernels, and its phase vels
%   par     - parameters structure
%   data    - obs data structure with all datatypes 
% 
% OUTPUTS
%   predata - structure identical to input data structure, but with
%             predicted data, rather than observed data
%%
% An important component is the layerising of the model - conversion of
% continuous model into a bunch of layers, with coarseness partly
% determined by the minimum dVs in any layer (specified as an input). The
% layerised 1D model is also output from this function.

%% ===================  PREPARE DATA STRUCTURE  ===================

for id = 1:length(par.inv.datatypes)
    pdtyps(id,:) = parse_dtype(par.inv.datatypes{id}); 
end

%% ======================  SURFACE WAVES  ======================
[ modptb ] = calc_Vperturbation(Kbase.modelk,model);

for id = 1:length(par.inv.datatypes)
    dtype = par.inv.datatypes{id};
    pdtyp = parse_dtype(dtype);
    if ~strcmp(pdtyp{1},'SW'), continue, end
    

%% --------------------  Phase Velocities  --------------------
    switch pdtyp{2}

        case {'Ray','Lov'}

            % calc. perturbation values from 0==>1 and use to calc dc/c           
            Np = length(Kbase.(pdtyp{2}).phV);
            est_dc_c = zeros(Np,1);

            kfld = {'Vsv','Vsh','Vpv','Vph','rho';'dvsv','dvsh','dvpv','dvph','drho'};

            zind = find(modptb.Z<max(Kbase.(pdtyp{2}).Kph{1}.Z/1000)); 

            for ip = 1:Np
                for ik = 1:size(kfld,2)
                    dr = diff(modptb.Z(zind))*1e3; % km to m
                    K = midpts(Kbase.(pdtyp{2}).(['K',pdtyp{3}(1:2)]){ip}.(kfld{1,ik})(zind));
                    dval = midpts(modptb.(kfld{2,ik})(zind));
                    est_dc_c(ip) = est_dc_c(ip) + dr'*(K.*dval);
                end
            end
            
            % est_dc_c applies to all periods in K. But a specific dataset might not have all those periods. Interpolate est_dc_c to the same periods of this dataset. 
            period_interp   = predata.(dtype).periods; % We want est_dc_c at these periods. 
            period_k        = Kbase.(pdtyp{2}).periods; % We have est_dc_c at these periods
            est_dc_c_interp = interp1(period_k, est_dc_c, period_interp, 'spline'); % "spline"... shouldn't matter each of period_interp is in period_k. But, I used linear in case of future code changes. 
            phV_interp      = interp1(period_k, Kbase.(pdtyp{2}).(pdtyp{3}), period_interp, 'spline'); 
            predata.(dtype).phV = (1+est_dc_c_interp).*phV_interp; % estimated model1 phase velocities
            %!%! Modify if including group velocity. if pdtyp{3} grV, interpolate that. Otherwise, phV. 
            
% % %             % Check interpolated and actual phase velocities match. Comment out if you believe this is working. 
% % %             figure(1); clf; hold on; box on; set(gca, 'linewidth', 1.5);
% % %             set(gcf, 'pos', [-929 622 484 300], 'color', 'white'); 
% % %             xlabel('Period (s)'); ylabel('Phase velocity (km/s)'); 
% % %             title('Velocity (phase/group), all periods versus interpolated for this dataset', 'fontweight', 'normal'); 
% % %             hand_full   = plot(Kbase.(pdtyp{2}).periods, Kbase.(pdtyp{2}).(pdtyp{3}), ...
% % %                 '-o', 'color', 'k'); 
% % %             hand_interp = plot(predata.(dtype).periods , phV_interp,                 ...
% % %                 '-x', 'color', 'b', 'linewidth', 1.5); 
% % %             lgd = legend([hand_full, hand_interp], 'All freq', 'Interp freq'); 
% % %             set(lgd, 'loc', 'best'); 

%% --------------------  HV ratios  --------------------
   
        case {'HV'}

            % these should be the same each time...
            zzz = [Kbase.(pdtyp{2}).KHV{1}.Z1(1); ... % Include 0 so we dull full integration. 
                0.5*(Kbase.(pdtyp{2}).KHV{1}.Z1 + Kbase.(pdtyp{2}).KHV{1}.Z2); ...
                Kbase.(pdtyp{2}).KHV{1}.Z2(end)]; ;
            dvs_vs = linterp(modptb.Z,modptb.dvsav,zzz)';
            dvp_vp = linterp(modptb.Z,modptb.dvpav,zzz)';
            drh_rh = linterp(modptb.Z,modptb.drho, zzz)';
            
            
            zzz    = reshape( zzz   , [],1 );
            dvs_vs = reshape( dvs_vs, [],1 );
            dvp_vp = reshape( dvp_vp, [],1 );
            drh_rh = reshape( drh_rh, [],1 );

% % %             %%% Plot interpolation
% % %             figure(2001); clf; hold on; 
% % %             tiledlayout(1,3, 'TileSpacing', 'compact'); 
% % %             
% % %             nexttile(1); cla; hold on; box on; set(gca, 'ydir', 'reverse', 'ylim', [-2, 300]); 
% % %             scatter(dvs_vs, zzz); 
% % %             scatter(modptb.dvsav,modptb.Z); 
% % %             %%%
            
            Np = length(Kbase.(pdtyp{2}).(pdtyp{3}));        
            for ip = 1:Np
                if ~isequal(zzz,[Kbase.(pdtyp{2}).KHV{1}.Z1(1); ... % Include 0 so we dull full integration. 
                        0.5*(Kbase.(pdtyp{2}).KHV{1}.Z1 + Kbase.(pdtyp{2}).KHV{1}.Z2); ...
                        Kbase.(pdtyp{2}).KHV{1}.Z2(end)])
                    zzz = [Kbase.(pdtyp{2}).KHV{ip}.Z1(1); ... % Include 0 so we dull full integration. 
                        0.5*(Kbase.(pdtyp{2}).KHV{ip}.Z1 + Kbase.(pdtyp{2}).KHV{ip}.Z2); ...
                        Kbase.(pdtyp{2}).KHV{ip}.Z2(end)]; ;
                    dvs_vs = linterp(modptb.Z,modptb.dvsav,zzz)';
                    dvp_vp = linterp(modptb.Z,modptb.dvpav,zzz)';
                    drh_rh = linterp(modptb.Z,modptb.drho, zzz)';
                    zzz    = reshape( zzz   , [],1 );
                    dvs_vs = reshape( dvs_vs, [],1 );
                    dvp_vp = reshape( dvp_vp, [],1 );
                    drh_rh = reshape( drh_rh, [],1 );
                end

                % Get kernels. 
                Kzh_Vs  = Kbase.(pdtyp{2}).KHV{ip}.Kzh_Vs ; 
                Kzh_Vp  = Kbase.(pdtyp{2}).KHV{ip}.Kzh_Vp ; 
                Kzh_rho = Kbase.(pdtyp{2}).KHV{ip}.Kzh_rho; 
                
                % Add values for z=0 and end, so we can use trapz for integral. 
                Kzh_Vs  = [Kzh_Vs(1) ; Kzh_Vs ; Kzh_Vs(end) ]; 
                Kzh_Vp  = [Kzh_Vp(1) ; Kzh_Vp ; Kzh_Vp(end) ]; 
                Kzh_rho = [Kzh_rho(1); Kzh_rho; Kzh_rho(end)]; 
                
                dHV = sum(trapz(zzz, ...
                                     (dvs_vs.*Kzh_Vs + ...
                                      dvp_vp.*Kzh_Vp + ...
                                      drh_rh.*Kzh_rho) )); % Trapz returns three values: the integral over each kernel. Then we need to sum each of those.           
                
                predata.(dtype).HVr(ip) = 1./( (1./Kbase.(pdtyp{2}).(pdtyp{3})(ip)) + dHV ); % Predata has HV, not ZH. Toshiros kernels are dZH. So add dZH to our 1/HV, then convert back to HV. brb2022.07.14
%                 predata.(dtype).HVr(ip) = Kbase.(pdtyp{2}).(pdtyp{3})(ip) - dHV; % Zach's version, which didn't consider HV versus ZH
            end           
    end
end


end

