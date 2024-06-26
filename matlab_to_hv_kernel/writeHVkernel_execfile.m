function writeHVkernel_execfile( execfile,modelfile,ofile,logfile)
% writeHVkernel_execfile( execfile,modelfile,ofile,logfile)
%   
% Function to write execution file for HVkernel code
% 
% INPUTS:
%  execfile  - name of execution file to write
%  modelfile - name of file with model description
%  ofile     - name of output file with all phV, HVratio, kernel
%  logfile   - name of file to print screen output to

paths = getPaths(); 

%% write synth.in parameter file
fid = fopen(execfile,'w');
fprintf(fid,'#!/bin/csh\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,'echo "Calculating HV ratios and kernels"\n');
%
fprintf(fid,'#\n');
%

fprintf(fid,['set xdir=' paths.HV_ellipticity '/bin\n']); % TODOpath
fprintf(fid,'$xdir/HVkernel << ! > %s\n',logfile);
fprintf(fid,'%s\n',modelfile);
fprintf(fid,'%s\n',ofile);
fprintf(fid,'!\n');

fclose(fid);

end




