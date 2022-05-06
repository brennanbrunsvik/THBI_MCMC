function [HVr,HVK,phV,grV] = run_HVkernel(model,swperiods,ID,ifdelete,ifplot,ifverbose)
% [HVrs,HVKs,phVs] = run_HVkernel(model,swperiods,ID,ifdelete,ifplot,ifverbose)
% 
% Function to run HV kernel script for a given model and extract the phase
% velocities and kernels at a bunch of input periods. 
% 
% Outputs are horizontal / vertical values, positive for retrograde motion.
% 

tic

if nargin < 3 || isempty(ID)
    ID = 'eg';
end
if nargin < 4 || isempty(ifdelete)
    ifdelete = true;
end
if nargin < 5 || isempty(ifplot)
    ifplot = false;
end
if nargin < 6 || isempty(ifverbose)
    ifverbose = true;
end

paths = getPaths(); 

%% filenames
if ~ischar(ID), ID = num2str(ID);end
execfile = [ID,'.run_HVker'];
modfile = [ID,'.model'];
ofile = [ID,'.out'];
logfile = [ID,'.log'];


%% =======================================================================
% % % brb2022.04.02 See if I can execute in ram folder. Sometimes a try catch doesn't permit us to change back to ram folder. 
% % % wd = pwd;
% % % cd([paths.THBIpath '/matlab_to_hv_kernel']); % bb2021.12.07 Why is this cd here? cd should be super slow, but I haven't seen this line come up in profilers...


%% model is an input file or a matlab structure?
if ischar(model) && java.io.File([pwd '/' model]).exists; %exist(model,'file')==2 %TODOEXIST bb2021.11.22 exist is SUPER slow
    modfile = model;
    delcard = false;
else
% 	writeHVkernel_modfile(modfile,model.Z,model.Vp,model.Vs,model.rho,[],[],1./swperiods);
	writeHVkernel_modfile(modfile,model.z,model.VP,model.VS,model.rho,[],[],1./swperiods);
    delcard =true;
end

writeHVkernel_execfile( execfile,modfile,ofile,logfile);
fileattrib(execfile, '+x'); 


%% do MINEOS on it
if ifverbose
    fprintf('    > Running HV kernel computation code. \n    > Will take some time...')
end
% [status,cmdout] = system(['/opt/local/bin/gtimeout 100 ./',execfile]);
[status,cmdout] = system([paths.timeout ' 15 ./',execfile]); % TODOPath
if status ~= 0; warning('hv kernel exit status ~= 0.'); end
    %brb2022.04.05 Changing from 100s timeout to 15s. 
if ifverbose
     fprintf(' success!\n')
end
%% read modes output
if status~=124
    try
    [HVr,HVK,phV,grV] = readHVkernel_ofile(ofile,swperiods,ifplot);
    HVr = -1./HVr;
    catch e 
        fprintf('\n%s\n',getReport(e)); 
        error('some error - check model file layers not too thin!\n')
    end
    phV = phV(:);
    grV = grV(:);
else 
    error('KVkernels did not finish in 100s')
end
    


%% delete files
if ifdelete
    delete(execfile,ofile);
    if java.io.File([pwd '/' logfile]).exists, delete(logfile); end %TODOEXIST bb2021.11.22 exist is SUPER slow
    if delcard, delete(modfile); end
end
% % % cd(wd); brb2022.04.02 Not changing directories cause I was getting stuck in HV folder. See earlier part of this file for another cd I commented out. 

% %% plot
% if ifplot
%     figure(88), clf; set(gcf,'pos',[331 385 848 613]);
%     ax1 = axes; hold on;
%     % dispersion curves
%     hd(1)=plot(ax1,swperiods,phV,'o-','linewidth',2);
%     hd(2)=plot(ax1,swperiods,grV,'o-','linewidth',2);
%     hl = legend(ax1,hd,{'Phase (c)','Group (U)'},'location','southeast');
%     set(hl,'fontsize',16,'fontweight','bold')
%     set(ax1,'fontsize',16)
%     xlabel(ax1,'Period (s)','interpreter','latex','fontsize',22)
%     ylabel(ax1,'Velocity (km/s)','interpreter','latex','fontsize',22)
% end
if ifverbose
    fprintf('HV   %s took %.5f s\n',ID,toc)
end

 