clear all
close all

if exist('ALLrequests','dir')~=7, mkdir('ALLrequests'); end


evdata1_stations % evdata1_database.m is the new version of this I guess? it does produce stainfo, so maybe... 
stainfo_master = stainfo;

% request data
for is = 1:length(stainfo_master)
    fprintf('\n============================================\n')
    fprintf('Requesting %s %s...',stainfo_master(is).StationCode,stainfo_master(is).NetworkCode)
    reqfile = evdata2_WAVEFORMS_breqfast(stainfo_master(is).StationCode,...
                                         stainfo_master(is).NetworkCode,...
                                         true,false);
    for ip = 1:length(reqfile)
        movefile(reqfile{ip},'ALLrequests')
    end
end
return

pause(3*60*60)
% process data
for is = 1:length(stainfo_master)
    fprintf('\n============================================\n')
    fprintf('Downloading %s %s...',stainfo_master(is).StationCode,stainfo_master(is).NetworkCode)
    try 
    [~,datafile] = evdata2_WAVEFORMS_breqfast(stainfo_master(is).StationCode,...
                                         stainfo_master(is).NetworkCode,...
                                         false,true);
%     movefile([datafile,'.mat'],'DATA')                                     
    catch e 
        fprintf('\n%s\n',getReport(e)); 
        fprintf('... NO DATA?! Might break all code.\n')
    end
end
