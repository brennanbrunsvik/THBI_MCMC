function [par, inv] = update_bayes_inv_parms(parOrig, stamp);
% Run default bayes_inv_parms, then update with this function. 
% There should be a unique stamp for each unique test. 
% The stamp should determine what folder the results are saved in. 

par = parOrig; 
str_temp = split(stamp, '/'); 

% Number of iterations, and such. Can use to determine which tests run for
% for inversion, and which tests get cut short for debug. 
niter_only   = 16000; 
burnin_only  = 4000 ; 
cooloff_only = 3000 ; 
nchains_only = 12   ; 

niter_only   = 400; 
burnin_only  = 30 ; 
cooloff_only = 20 ; 
nchains_only = 3  ; 
% niter_only   = 16000; 
% burnin_only  = 4000 ; 
% cooloff_only = 3000 ; 
% nchains_only = 12   ; 

% % For testing telewavesim
% par.synth.samprate = 60; % TODO figure this out. 
% par.forc.nsamps = par.synth.samprate / 10 * 10^13; % 2^12; % TODO figure this out. 
% par.synth.noise_sigma_BW_Ps = 0.000;%1; 
% par.synth.noise_sigma_BW_Sp = 0.000;%1; 
% par.synth.propmat_or_telewavesim = 'telewavesim'; % propmat or telewavesim



if     strcmp(stamp, 'ENAM_trial'); 
    disp('Using default parameters') 

elseif strcmp(stamp, 'eus_mantle_anis'); 
    % par.inv.niter                     = niter_only; 
    % par.inv.burnin                    = burnin_only; 
    % par.inv.cooloff                   = cooloff_only; 
    % par.inv.nchains                   = nchains_only;  
    par.mod.mantle.xidepths = [0, 80]'; % Need at least 1 value. If shallower than the Moho (e.g. 0) it is shifted to the Moho depth. 
    par.datprocess.dat_version = 'HOPPER'; 


elseif strcmp(stamp, 'no_anis_mant'); 
    % par.inv.niter                     = niter_only; 
    % par.inv.burnin                    = burnin_only; 
    % par.inv.cooloff                   = cooloff_only; 
    % par.inv.nchains                   = nchains_only;  
    par.mod.mantle.xidepths = [0]'; % Need at least 1 value. If shallower than the Moho (e.g. 0) it is shifted to the Moho depth. 
    par.mod.mantle.xistd = 0; % No anisotropy in mantle. 

elseif strcmp(stamp, 'less_anis'); 
    % par.inv.niter                     = niter_only; 
    % par.inv.burnin                    = burnin_only; 
    % par.inv.cooloff                   = cooloff_only; 
    % par.inv.nchains                   = nchains_only;  
    par.mod.mantle.xidepths = [0, 80]'; % Need at least 1 value. If shallower than the Moho (e.g. 0) it is shifted to the Moho depth. 

elseif strcmp(stamp, 'more_anis'); 
    % par.inv.niter                     = niter_only; 
    % par.inv.burnin                    = burnin_only; 
    % par.inv.cooloff                   = cooloff_only; 
    % par.inv.nchains                   = nchains_only;  
    par.mod.mantle.xidepths = [60, 80, 110]'; % , 150

%%% First list things I'm hoping to actually put in the paper
elseif strcmp(stamp, 'standard_temp'); 
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  

% { Different data types alone 
elseif strcmp(stamp, 'SW_Ray_phV_only'); 
    par.inv.datatypes                 = {'SW_Ray_phV_eks','SW_Ray_phV_dal','SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
elseif strcmp(stamp, 'SW_Lov_phV_only'); 
    par.inv.datatypes                 = {'SW_Lov_phV'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
elseif strcmp(stamp, 'RF_Sp_ccp_only'); 
    par.inv.datatypes                 = {'RF_Sp_ccp'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
elseif strcmp(stamp, 'HKstack_P_only'); 
    par.inv.datatypes                 = {'HKstack_P'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
elseif strcmp(stamp, 'SW_HV_only'); 
    par.inv.datatypes                 = {'SW_HV'}   ;
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  
% } End different data types alone

elseif strcmp(stamp, 'all_no_hv'); 
%     par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
%         'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
%         'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'};    

    % brb2023/05/23 added code to get rid of one data type. Modify as needed. 
    dtp = par.inv.datatypes; 
    dtp = string(dtp); 
    dtp = dtp(dtp~="SW_HV")
    dtp = cellstr(dtp); 
    par.inv.datatypes = dtp; 

    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ; 

elseif strcmp(stamp, 'all_no_sp'); 
%     par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
%         'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
%         'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'};    

    % brb2023/05/23 added code to get rid of one data type. Modify as needed. 
    dtp = par.inv.datatypes; 
    dtp = string(dtp); 
    dtp = dtp(dtp~="RF_Sp_ccp")
    dtp = cellstr(dtp); 
    par.inv.datatypes = dtp; 

    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ; 

elseif strcmp(stamp, 'synth_no_sed'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     
    par.mod.sed.hmax                  = 0; 
    par.mod.sed.vsmin                 = 3.3;
    par.sed.vsmax                     = 3.3; 
    par.mod.force_no_new_prior        = true; 



%%% The rest of things were tests I ran while getting everything set up . 

    

% % % 'h_kappa_tests/degree_of_freedom/*'
% % elseif strcmp(str_temp{1}, 'h_kappa_tests'               ) && ...
% %        strcmp(str_temp{2}, 'degree_of_freedom'           ); % Set stamp to this to run this test
% %     
% %     disp('Testing degrees of freedom with h-kappa stacks')
% %     things = split(stamp, '/'); 
% %     value = str2num(things{end}); % Degrees of freedom is last part of stamp
% %     
% %     par.mod.data.deg_of_freedom.h_kappa = value; 
% %     
% %     
% % % 'h_kappa_tests/h_kappa_solo/sigma_constant/*'    
% % elseif strcmp(str_temp{1}, 'h_kappa_tests'   ) && ...
% %        strcmp(str_temp{2}, 'h_kappa_solo'    ) && ...
% %        strcmp(str_temp{3}, 'sigma_constant'  );     
% %    
% %     disp('h_kappa test. Solo. Constant sigma. ')
% %     things = split(stamp, '/'); 
% %     value = str2num(things{end}); % Value is last part of stamp
% % 
% %     par.mod.data.logstd_sigma = 0.0; 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value);
% %     par.inv.datatypes = {'HKstack_P'}; 
% % 
% % 
% % 
% % 
% % elseif strcmp(str_temp{1}, 'h_kappa_tests'                         ) && ...
% %        strcmp(str_temp{2}, 'observe_convergence'                   ) && ...
% %        strcmp(str_temp{3}, 'invert_sigma'                          );     
% %    
% % %     disp('h_kappa test. Solo. Constant sigma. ')
% %     things = split(stamp, '/'); 
% %     value = str2num(things{end}); % Value is last part of stamp
% % 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value); 
% %     
% %     par.mod.data.logstd_sigma = 0.05; 
% %     par.inv.datatypes = {'HKstack_P'}; 
% %     par.inv.niter = 12000; 
% %     par.inv.burnin = 4000; 
% %     par.inv.cooloff = 3000; 
% %     par.inv.nchains = 16; 
% % elseif strcmp(str_temp{1}, 'h_kappa_tests'                         ) && ...
% %        strcmp(str_temp{2}, 'observe_convergence'                   ) && ...
% %        strcmp(str_temp{3}, 'invert_sigma_false'                          );     
% %    
% % %     disp('h_kappa test. Solo. Constant sigma. ')
% %     things = split(stamp, '/'); 
% %     value = str2num(things{end}); % Value is last part of stamp
% % 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value);     
% %     
% %     par.mod.data.logstd_sigma = 0.00; 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value); 
% %     par.inv.datatypes = {'HKstack_P'};     
% %     par.inv.niter = 12000; 
% %     par.inv.burnin = 4000; 
% %     par.inv.cooloff = 3000; 
% %     par.inv.nchains = 16; 
% % elseif strcmp(str_temp{1}, 'h_kappa_tests'                         ) && ...
% %        strcmp(str_temp{2}, 'observe_convergence'                   ) && ...
% %        strcmp(str_temp{3}, 'invert_sigma'                          ) && ...
% %        strcmp(str_temp{4}, 'large_cooldown'                        );     
% %    
% % %     disp('h_kappa test. Solo. Constant sigma. ')
% %     things = split(stamp, '/'); 
% %     value = str2num(things{end}); % Value is last part of stamp
% % 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value);     
% %     
% %     par.mod.data.logstd_sigma = 0.05; 
% %     par.mod.data.prior_sigma.HKstack = struct('P',value); 
% %     par.inv.datatypes = {'HKstack_P'};     
% %     par.inv.niter = 16000; 
% %     par.inv.burnin = 8000; 
% %     par.inv.cooloff = 6000;
% %     par.inv.tempmax = 9; 
% %     par.inv.nchains = 16; 
% %     
    
elseif strcmp(stamp, 'lower_prior_sigma')
%     disp('Do stuff')
    par.mod.data.prior_sigma.HKstack.P = 0.1; 
        
    
elseif strcmp(stamp, 'prior_sigma_0.2_min_sigma_0.1')
%     disp('Do stuff')
    par.mod.data.prior_sigma.HKstack.P = 0.2;   
    par.mod.data.min_sigma.HKstack.P   = 0.1;     

    
elseif strcmp(stamp, 'prior_sigma_1_min_sigma_0.5')
%     disp('Do stuff')
    par.mod.data.prior_sigma.HKstack.P = 1;   
    par.mod.data.min_sigma.HKstack.P   = 0.5;    
    
    
elseif strcmp(stamp, 'prior_sigma_1_min_sigma_0.1_err')
%     disp('Do stuff')
    par.mod.data.prior_sigma.HKstack.P = 1;   
    par.mod.data.min_sigma.HKstack.P   = 0.1;    
    
    
elseif strcmp(stamp, 'prior_sigma_10_min_sigma_3')
%     disp('Do stuff')
    par.mod.data.prior_sigma.HKstack.P = 10;   
    par.mod.data.min_sigma.HKstack.P   = 3;    
    
    
elseif strcmp(stamp, 'HKappa_001'); 
    par.mod.data.prior_sigma.HKstack.P = .6; 
    par.mod.data.min_sigma.HKstack.P   = .1; 
    par.datprocess.HKappa.min_error    = 0.1; 
    par.datprocess.HKappa.scale_error  = 1; 
elseif strcmp(stamp, 'HKappa_002'); 
    par.mod.data.prior_sigma.HKstack.P = 1; 
    par.mod.data.min_sigma.HKstack.P   = .2; 
    par.datprocess.HKappa.min_error    = 0.1; 
    par.datprocess.HKappa.scale_error  = 1; 
elseif strcmp(stamp, 'HKappa_003'); 
    par.mod.data.prior_sigma.HKstack.P = 1; 
    par.mod.data.min_sigma.HKstack.P   = .01; 
    par.datprocess.HKappa.min_error    = 0.1; 
    par.datprocess.HKappa.scale_error  = 1; 
elseif strcmp(stamp, 'HKappa_004'); 
    par.mod.data.prior_sigma.HKstack.P = 1; 
    par.mod.data.min_sigma.HKstack.P   = .5; 
    par.datprocess.HKappa.min_error    = 0.01; 
    par.datprocess.HKappa.scale_error  = 100; 
    
elseif strcmp(stamp, 'HKappa_005'); 
    par.datprocess.HKappa.weightDistanceMax = 1; 
    par.datprocess.HKappa.weightDistanceMin = 1; 
elseif strcmp(stamp, 'HKappa_006'); 
    par.datprocess.HKappa.weightDistanceMax = 1; 
    par.datprocess.HKappa.weightDistanceMin = 0.5;
    
elseif strcmp(stamp, 'HKappa_007'); 
    par.mod.starting.HKappa.startAtHK = true; 
    
    
    
elseif strcmp(stamp, 'all_001'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.mod.starting.HKappa.startAtHK = true;   
    par.inv.niter                     = 16000; 
    par.inv.burnin                    = 6000; 
    par.inv.cooloff                   = 4500; 
    par.inv.nchains                   = 16; 
    


% { --- ONE CHAIN Different data types alone
elseif strcmp(stamp, 'SW_Ray_phV_only_one_chain'); 
    par.inv.datatypes                 = {'SW_Ray_phV'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = 1; 
elseif strcmp(stamp, 'SW_Lov_phV_only_one_chain'); 
    par.inv.datatypes                 = {'SW_Lov_phV'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = 1; 
elseif strcmp(stamp, 'RF_Sp_ccp_only_one_chain'); 
    par.inv.datatypes                 = {'RF_Sp_ccp'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = 1; 
elseif strcmp(stamp, 'HKstack_P_only_one_chain'); 
    par.inv.datatypes                 = {'HKstack_P'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = 1; 
elseif strcmp(stamp, 'SW_HV_only_one_chain'); 
    par.inv.datatypes                 = {'SW_HV'}   ;
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = 1;     
% } --- End test different data types alone   

% { --- A couple data types. 
elseif strcmp(stamp, 'HKstack_P___SW_HV_only__only'); 
    par.inv.datatypes                 = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  
% } ---

    
elseif strcmp(stamp, 'HK_fast'); 
    par.inv.datatypes                 = {'HKstack_P'};
    par.inv.niter                     = 500  ; 
    par.inv.burnin                    = 100  ; 
    par.inv.cooloff                   = 80   ; 
    par.inv.nchains                   = 16    ; 
elseif strcmp(stamp, 'SW_HV_fast'); 
    par.inv.datatypes                 = {'SW_HV'}   ;
    par.inv.niter                     = 500  ; 
    par.inv.burnin                    = 100  ; 
    par.inv.cooloff                   = 80   ; 
    par.inv.nchains                   = 16    ;  
elseif strcmp(stamp, 'HK_faster'); 
    par.inv.datatypes                 = {'HKstack_P'};
    par.inv.niter                     = 500  ; 
    par.inv.burnin                    = 100  ; 
    par.inv.cooloff                   = 80   ; 
    par.inv.nchains                   = 2    ;  
elseif strcmp(stamp, 'all_fast'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = 300  ; 
    par.inv.burnin                    = 100  ; 
    par.inv.cooloff                   = 70  ; 
    par.inv.nchains                   = 1    ; 
elseif strcmp(stamp, 'all_faster'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = 500  ; 
    par.inv.burnin                    = 100  ; 
    par.inv.cooloff                   = 80   ; 
    par.inv.nchains                   = 4    ; 

    
elseif strcmp(stamp, 'sage_gage'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'}; % No HV 
    par.mod.starting.HKappa.startAtHK = true;   
    par.inv.niter                     = 16000; 
    par.inv.burnin                    = 5000 ; 
    par.inv.cooloff                   = 4000 ; 
    par.inv.nchains                   = 12   ; % Less chains. So we can run more stations. 
elseif strcmp(stamp, 'sage_gage_faster'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'}; % No HV 
    par.mod.starting.HKappa.startAtHK = true;   
    par.inv.niter                     = 700; 
    par.inv.burnin                    = 200 ; 
    par.inv.cooloff                   = 100 ; 
    par.inv.nchains                   = 12   ; % Less chains. So we can run more stations. 
    
    
    
elseif strcmp(stamp, 'most_fast'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'}; % No HV 
    par.mod.starting.HKappa.startAtHK = true;   
    par.inv.niter                     = 500 ; 
    par.inv.burnin                    = 100 ; 
    par.inv.cooloff                   = 80  ; 
    par.inv.nchains                   = 12  ; % Less chains. So we can run more stations. 
elseif strcmp(stamp, 'most_003'); 
    par.inv.datatypes = {'SW_Ray_phV', 'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P'}; % No HV 
    par.mod.starting.HKappa.startAtHK = true ;   
    par.inv.niter                     = 16000; 
    par.inv.burnin                    = 5000 ; 
    par.inv.cooloff                   = 4000 ; 
    par.inv.nchains                   = 12   ; % Less chains. So we can run more stations. 


% Sp receiver function, upweight at depth. 
elseif strcmp(stamp, 'ccp_weights_1'); 
    par.inv.datatypes                 = {'RF_Sp_ccp'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
    par.datprocess.CCP.weight_depth_val = [-10,1 ; 6371,1]; % Constant weight. 1. 
elseif strcmp(stamp, 'ccp_weights_2'); 
    par.inv.datatypes                 = {'RF_Sp_ccp'};
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only; 
    par.datprocess.CCP.weight_depth_val = [-10,0.3 ; 50,0.3 ; 100,1 ; 6371,1]; % Upweight at depth. This gets normalized.  

elseif strcmp(stamp, 'many_sw_authors'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqeik','SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = 16000; 
    par.inv.burnin                    = 5000 ; 
    par.inv.cooloff                   = 4000 ; 
    par.inv.nchains                   = 12   ; % Less chains. So we can run more stations. 
elseif strcmp(stamp, 'many_sw_authors_fast'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqeik','SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = 300; 
    par.inv.burnin                    = 100; 
    par.inv.cooloff                   = 80; 
    par.inv.nchains                   = 3   ; % Less chains. So we can run more stations. 

elseif strcmp(stamp, 'add_sediment_try2'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqeik','SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  

elseif strcmp(stamp, 'SW_all'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqeik', 'SW_Ray_phV_lyneqhelm', 'SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'SW_HV'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     
    
    par.inv.verbose = false; 

elseif strcmp(stamp, 'all_highres_layer'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm', 'SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'SW_HV', 'RF_Sp_ccp', 'HKstack_P'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     

elseif strcmp(stamp, 'simplify'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm', 'SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'SW_HV', 'RF_Sp_ccp'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     
  
    
    
    par.mod.sed.hmax                  = 0     ; 
    par.mod.sed.hstd                  = 0     ; 
    par.mod.crust.vpvsmax             = 1.8   ; 
    par.mod.crust.vpvsmin             = 1.8   ; % Can't use HK stack if there is no vpvs variatoin. 
    par.mod.crust.vpvsstd             = 0     ; 
    par.mod.crust.ximax               = 1     ; 
    par.mod.crust.ximin               = 1     ; 
    par.mod.crust.xistd               = 0     ; 
    par.mod.force_no_new_prior        = true  ; % For debugging only. 

    
    
    par.mod.sed.hmax                  = 0     ; 
    par.mod.sed.hstd                  = 0     ; 
    par.mod.force_no_new_prior        = true  ; % For debugging only. 
elseif strcmp(stamp, 'no_vpvs'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm', 'SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'SW_HV', 'RF_Sp_ccp'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     
  
    
   
    par.mod.crust.vpvsmax             = 1.8   ; 
    par.mod.crust.vpvsmin             = 1.8   ; % Can't use HK stack if there is no vpvs variatoin. 
    par.mod.crust.vpvsstd             = 0     ; 
    par.mod.force_no_new_prior        = true  ; % For debugging only. 
elseif strcmp(stamp, 'no_xi'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm', 'SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'SW_HV', 'RF_Sp_ccp'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;     
  
    par.mod.crust.ximax               = 1     ; 
    par.mod.crust.ximin               = 1     ; 
    par.mod.crust.xistd               = 0     ; 
    par.mod.force_no_new_prior        = true  ; % For debugging only. 
    

   
elseif strcmp(stamp, 'all_003'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ; 

        
    
    
 %%% COnclusion of next two tests: use higher synth period, and 10 km
 %%% spacing of layers, and dv doesn't matter but 0.15 is fine. 
elseif strcmp(stamp, 'propmat_res_0_01'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  
    par.forc.mindV                    = 0.01; %  
elseif strcmp(stamp, 'propmat_res_0_1'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'}; 
    par.inv.niter                     = niter_only  ; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only; 
    par.inv.nchains                   = nchains_only;  
    par.forc.mindV                    = 0.1; %      

elseif strcmp(stamp, 'all_sp_weight'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;     
    par.datprocess.CCP.weight_depth_val = [-10,0.3 ; 30,0.3 ; 70,1 ; 6371,1]; % Upweight at depth. This gets normalized.  

elseif strcmp(stamp, 'all_sp_weight_2'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;     
    par.datprocess.CCP.weight_depth_val = [-10,0.3 ; 30,0.3 ; 70,1 ; 6371,1]; % Upweight at depth. This gets normalized.  

elseif strcmp(stamp, 'layerise_normal'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;
    par.datprocess.CCP.layerise_version   = 'normal'; 
elseif strcmp(stamp, 'layerise_no_sed_propmat'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;  
    par.datprocess.CCP.layerise_version   = 'no_sed'; 

elseif strcmp(stamp, 'all_simple_parent'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;    
    par.datprocess.CCP.layerise_version   = 'normal'; 
    par.datprocess.CCP.simple_parent_pulse = true;
    par.mod.force_no_new_prior        = true; warning('no new prior = true')

    
    
elseif strcmp(stamp, 'all_simple_parent_no_sed'); 
    par.inv.datatypes = {'SW_Ray_phV_eks', 'SW_Ray_phV_dal', ...
        'SW_Ray_phV_lyneqhelm','SW_Ray_phV_lynant',...
        'SW_Lov_phV', 'RF_Sp_ccp', 'HKstack_P', 'SW_HV'};      
    par.inv.niter                     = niter_only; 
    par.inv.burnin                    = burnin_only ; 
    par.inv.cooloff                   = cooloff_only ; 
    par.inv.nchains                   = nchains_only   ;    
    par.datprocess.CCP.layerise_version   = 'normal'; 
    par.datprocess.CCP.simple_parent_pulse = true;
    par.mod.sed.hmax                  = 0; 
    par.mod.force_no_new_prior        = false; 

    
    
elseif strcmp(stamp, 'low_noise_sp'); 
    par.synth.noise_sigma_BW_Sp = 0; 
    par.synth.noise_sigma_RF_Sp = 0; 
    
elseif strcmp(stamp, 'no_noise'); 
    par.synth.noise_sigma_SW_Ray = 0.000;         
    par.synth.noise_sigma_SW_Lov = 0.000;         
    par.synth.noise_sigma_SW_HV  = 0.000;         
    par.synth.noise_sigma_BW_Sp  = 0.000;         
    par.synth.noise_sigma_BW_Ps  = 0.000;         
    par.synth.noise_sigma_RF_Sp  = 0.000;         
    par.synth.noise_sigma_RF_Ps  = 0.000; 
elseif strcmp(stamp, 'no_noise_no_hv'); 
    par.synth.noise_sigma_SW_Ray = 0.000;         
    par.synth.noise_sigma_SW_Lov = 0.000;         
    par.synth.noise_sigma_SW_HV  = 0.000;         
    par.synth.noise_sigma_BW_Sp  = 0.000;         
    par.synth.noise_sigma_BW_Ps  = 0.000;         
    par.synth.noise_sigma_RF_Sp  = 0.000;         
    par.synth.noise_sigma_RF_Ps  = 0.000; 
    dtp = string(par.inv.datatypes); 
    par.inv.datatypes = cellstr(dtp(dtp ~= 'SW_HV')); 
    
    

    
    

    
end

inv = par.inv; 

end


