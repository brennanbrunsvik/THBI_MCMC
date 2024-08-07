% close all 
% clear all % Cannot clear all, because then we allways reset network_manual and station_manual below. 
%% Setup
% These define what we are running. Make a list of all desired options. 
clear; restoredefaultpath; 
% Temporary brb20240604
addpath('/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/transition_to_russell_mineos/new_code'); % Remove when ready
addpath('/Users/brennanbrunsvik/Documents/repositories/Peoples_codes/MINEOS_synthetics/run_MINEOS'); % Move when ready 

STAMP_all =          {'standard'       };
network_manual_all = {'testnwk'        }; 
station_manual_all = {'simple_layers_1'}; %


start_dir = pwd(); 
for istamp = 1:length(STAMP_all); 
    cd(start_dir); % Don't know if directories get messed up, but change to here just in case.
    STAMP = STAMP_all{istamp};
    network_manual = network_manual_all{istamp}; 
    station_manual = station_manual_all{istamp}; %


    run('../a0_STARTUP_BAYES.m')
    
    proj = struct('name', 'transition_to_russell_mineos'); % bb2021.08.04 changed from EXAMPLE because I don't have the example data files. %,'EXAMPLE');
    paths = getPaths(); 
    proj.STAinversions = paths.STAinversions; 
    proj.dir = [fileparts(mfilename('fullpath')),'/'];
    % proj.dir = paths.STAinversions; 
    proj.STAinversions = paths.STAinversions; ; % [proj.dir,'inversion_results/'];
    save([proj.dir,'project_details.mat'],'proj')
    
    wd = pwd; addpath(wd);
    cd(proj.dir); 
    
    %% specify details of this run
    generation = 0; % generation of solution and data processing
    gc = '';
    BWclust = '';

    onesta = '';
    
    %% put parameters in place 
    global run_params
    
    % you can obviously adapt these (likely in some loop over stations etc.) 
    % to be appropriate for your dataset
    run_params.projname = proj.name; % from above
    run_params.gc = gc; % great circle distance of body wave data, if relevant
    run_params.BWclust = BWclust; % cluster of BW data, if relevant
    run_params.datN = generation; % processing iteration, if relevant
    run_params.STAMP = STAMP; % NEED - some identifier for this inversion run
    run_params.overwrite = 1; % do you want to overwrite previous results?
    % if ~ (exist('network_manual', 'var') && exist('station_manual', 'var')) ; 
    fprintf('\nReseting to %s.%s\n',network_manual,station_manual)
    % end
    run_params.sta = station_manual; % name of station
    run_params.nwk = network_manual; % name of network
    
    %% Run it
    fprintf('Starting synthetic test %s %s %s\n', network_manual, station_manual, STAMP)
    execute_run_all_chains; % Put "run_all_chains.m" in a function, so that maybe "clear" won't erase values like STAMP_all 
end

function execute_run_all_chains
    run_all_chains;% Put "run_all_chains.m" in a function, so that maybe "clear" won't erase values like STAMP_all 
end