%% specify details of this run
generation = 1; % generation of solution and data processing
gc = 1;
BWclust = 1;
onesta = '';
overwrite = true;

STAMP_all = {...
    'eus_mantle_anis',...
}; % This determines which tests we want to run now. They will run sequentially, not in parallel (each station only has one ram folder. )

for istamp = [1:length(STAMP_all)]; 
    STAMP = STAMP_all{istamp}; 

    %% setup data and stuff. 
    run('../a0_STARTUP_BAYES.m')


    %%%%% Important! Must define network and station before runnig this! 
    % These should already be defined in the Bash/Slurm script which calls
    % this Matlab script. But, you aren't running from Bash/Slurm, we can
    % use these default values. 
    if ~ (exist('network_manual', 'var') && exist('station_manual', 'var')) ; 
        network_manual = 'US'; % This is NOT used if station_manual is already in your workspace. 
        station_manual = 'CEH'; % This is NOT used if station_manual is already in your workspace. 
        fprintf('\nReseting to %s.%s\n',network_manual,station_manual)
    end
    disp('Network and station') 
    disp(network_manual) 
    disp(station_manual)

    % Paths stuff
    paths = getPaths(); 
    this_folder = split(pwd, '/'); 
    proj = struct('name',this_folder{end});
    proj.dir = [paths.THBIpath '/' proj.name];
    wd = pwd; addpath(wd);
    cd(proj.dir);

    %% load project, station, and request details and request details
    try
        load([proj.dir,'/project_details.mat']);
    catch e 
        fprintf('\n%s\n',getReport(e)); 
        fprintf('\n\nWe might not have had the correct project_details.mat. Attempting to run evdata1_database.m to generate it. \n\n')
        run([proj.dir,'/evdata1_database.m']);
        fprintf('\n\nRan evdata1_database.m.\nUser, try manually try running RUN_one_station.m again.\n\n')
        return
    end
    load([proj.infodir,'stations.mat']); % bb2021.09.28 Get this using evdata1_database.m

    %% put parameters in place for running all stations
    global run_params

    run_params.projname = proj.name;
    run_params.gc = gc;
    run_params.BWclust = BWclust;
    run_params.datN = generation;
    run_params.STAMP = STAMP;
    run_params.overwrite = overwrite;

    tempSta = and(string(stainfo.nwk)==network_manual, string(stainfo.stas)==station_manual); 

    tempStaInd = find(tempSta); 

    %% ==================  LOOP OVER STATIONS IN DB  ================== 
    % No, actually just find the right station and run it. 
    for is = tempStaInd; 

        if exist('onesta') && ~isempty(onesta)
            if ~strcmp(stainfo.stas{is},onesta), continue; end
        end

        fprintf('\n'); for i=1:3, for j=1:40, fprintf('**'); end; fprintf('*\n'); end; fprintf('\n');

        fprintf('STATION: %s\n',stainfo.stas{is})
        fprintf('NETWORK: %s\n\n',stainfo.nwk{is})
        run_params.sta = stainfo.stas{is};
        run_params.nwk = stainfo.nwk{is};

        % do the work (and make all the Mineos files) in a workdir
        if exist('workdir','dir')~=7, mkdir('workdir'); end
        cd(proj.dir)

        execute_run_all_chains

        cd(proj.dir)
    end

end

function execute_run_all_chains
    run_all_chains;
end