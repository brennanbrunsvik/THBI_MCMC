% Code moved to run_hk_test.m 

% % % 
% % % global run_params
% % % paths = getPaths(); 
% % % 
% % % projname = run_params.projname;
% % % sta = run_params.sta;
% % % nwk = run_params.nwk;
% % % gc = run_params.gc;
% % % BWclust = run_params.BWclust;
% % % datN = run_params.datN;
% % % STAMP = run_params.STAMP;
% % % overwrite = run_params.overwrite;
% % % global projdir TRUEmodel
% % % projdir = [paths.THBIpath,'/',projname,'/'];
% % % cd(projdir);
% % % run([paths.THBIpath,'/a0_STARTUP_BAYES']);
% % % load('project_details'); %TODO_STATION_NETWORK bb2021.11.12
% % % addpath([proj.dir,'matguts/']);
% % % 
% % % %% PARMS
% % % run parms/bayes_inv_parms
% % % [par, inv] = update_bayes_inv_parms(par, STAMP); % Modify this function to make different tests. 
% % % 
% % % 
% % % if strcmp(projname,'SYNTHETICS')
% % %     par.stadeets = struct('sta',sta','nwk',nwk'); 
% % % 	noisesta = 'RSSD';
% % % 	noisenwk = 'IU';
% % % 	noisegcarcs = [73,38];
% % % 	noiseshape = 'real'; % 'white' or 'real'
% % % 	noiseup = 0.5; % factor to increase real noise
% % % end
% % % 
% % % if strcmp(projname,'SYNTHETICS') || strcmp(projname,'LAB_tests')
% % %     par.synth.noise_sta_deets = struct('datadir',['/Volumes/data/THBI/US/STAsinv/',noisesta,'_dat20/'],...
% % %                          'sta',noisesta,'nwk',noisenwk,'gc',noisegcarcs,'noiseup',noiseup,'noiseshape',noiseshape);
% % % end
% % % 
% % % par.inv.BWclust = BWclust;
% % % ifsavedat = false;
% % % 
% % % %% get saving things ready
% % % par.proj = proj;
% % % avardir = sprintf('%s%s_%s_dat%.0f/',par.proj.STAinversions,sta,nwk,datN);
% % % resdir = [avardir,STAMP];
% % % if ~exist(resdir,'dir'), try mkdir(resdir); catch, error('Looks like no path to output directory - is it mounted?'); end, end
% % % 
% % % par.data = struct('stadeets',struct('sta',sta,'nwk',nwk,'Latitude',[],'Longitude',[]),...
% % %                   'gc',gc,'datN',datN,'avardir',avardir);
% % % 
% % % par.res.STAMP = STAMP;
% % % par.res.resdir= resdir;
% % % par.res = orderfields(par.res,{'STAMP','resdir','zatdep'});
% % % 
% % % %% Get some directories ready. 
% % % % Switch to execution folder, to make synthetic data. 
% % % prev_dir = pwd(); 
% % % cd(paths.ramDrive); % Execute everything from a folder in ram for major speedup. 
% % % mkdir([nwk '_' sta]); cd([nwk '_' sta]); % Go to station specific folder to keep things clean . TODO just to cd once. 
% % % 
% % % %% HK tests, analysis, starts here. 
% % % [trudata,par] = a2_LOAD_DATA_hk_test(par, 'nwk', nwk, 'sta', sta);
% % % plot_TRU_WAVEFORMS(trudata);
% % % 


