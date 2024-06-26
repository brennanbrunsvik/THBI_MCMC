function [traces,tt,status,cmdout] = run_telewavesim(LAYmodel,ID,ph,samprate,ray_parm,synthperiod,nsamps,cutf,sourc)
% Most argument checks are done in run_propmat_or_telewavesim. 
if isempty(samprate); 
    samprate = 60; 
end
if isempty(nsamps); 
    nsamps = 2^13; 
end
if isempty(ray_parm); 
    ray_parm = 0.06; 
end 
if ~all(unique(factor(nsamps))==2)
    error('Nsamps must be some power of 2')
end

% This function requires the proper py object in Matlab. 
% You can open it like this: 
% pyenv('Version', '~/opt/anaconda3/envs/tws/bin/python', ... % Use anaconda environment where telewavesim is installed. This affects the entire Matlab session. TODO define this path in somewhere more obvious. 
%     'ExecutionMode','OutOfProcess')
% Then you need to make sure the python path includes the path to the
% Python telewavesim function. You can add it like this: 
% insert(py.sys.path, int32(0), '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/matlab_to_telewavesim')

% Function to run the propagator matrix code for a given layerised model. 

% demoPlot = true; % whether to plot the propmat results
demoPlot = strcmp(ph, 'Ps'); 


%%% Done getting arguments. 
paths = getPaths(); 

% remaining parms
obsdist = 0;
ocomps = 2; % 1 is [x,y,z], 2 is [r,t,z]

sampperiod = 1/samprate; 

%% filenames
if ~ischar(ID), ID = num2str(ID);end
modfile =    [ ID,'.mod'];

%% =======================================================================

if strcmp(ph,'Ps')
    Vbot = LAYmodel.Vp(end);
elseif strcmp(ph,'Sp')
    Vbot = LAYmodel.Vs(end);
end
nlay = LAYmodel.nlay;

%% write to telewavesim format
writeTELEWAVESIM_modfile(LAYmodel,modfile); 
if strcmp(sourc, 'sine'); 
    error('telewavesim wrapper not written for sin input. Use gauss instead. ')
end

%% Call telewavesim 
% Simple test parameters. 
% Left here in comments to show examples of values with correct units. 
% modfile = './demo.txt'; 
% wvtype = 'P';
% npts = 3000;
% dt = 0.01;
dp = 0; % 2000.0; % TODO new input argument
use_obs = false; % true; % TODO new input argument
c = 1.5; % Water speed
rhof = 1027.0; % Water density
% slow = 0.06;
ray_parm = ray_parm / 111.1949; % This is "slow" in telewavesim
baz = 180; % Angle in degree. 
% TODO how to handle synth period? 

output = py.run_telewavesim_py.run_telewavesim( ...
    modfile, ph(1), nsamps, sampperiod, dp, use_obs, c, rhof, ray_parm, baz); %ph(1) -> this chooses the incident wave type. So, the first part of our receiver function name should be the wave type we want. P, for Ps. 
output = cell(output); 
traces = double(output{1})'; % In RTZ
tt = double(output{2})'; 
status = ''; 
cmdout = ''; 

delete(modfile);  % TODO bring back delete

if demoPlot; % plot
    figure(2); clf, hold on
    comps = {'VERTICAL','RADIAL','TRANSVERSE'}; 
    traces2 = traces(:,[3,1,2]);
    for ip = 1:3
        subplot(3,1,ip)
        plot(tt,traces2(:,ip),'Linewidth',1.5)
        xlim([0 max(tt)]);
        ylabel(comps{ip},'fontsize',19,'fontweight','bold')
    end
    set(gcf,'position',[680         273        1058         825])
end


