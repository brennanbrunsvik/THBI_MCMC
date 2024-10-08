function writeMINEOSeig_recover( execfile,eigfile,l_last )
% writeMINEOSexecfile( execfile,cardfile,modefile,eigfile,ascfile,logfile)
%   
% Function to write execution file for MINEOS code
% 
% INPUTS:
%  execfile  - name of execution file to write
%  eigfile   - name of eigenfunctions output binary file to fix
%  l_last    - last successful mode in this eig file

paths = getPaths(); 

%% write synth.in parameter file
fid = fopen(execfile,'w');
fprintf(fid,'#!/bin/csh\n');
%
fprintf(fid,'#\n');
%
fprintf(fid,['set xdir=' paths.CADMINEOS '/bin\n']); 
fprintf(fid,'$xdir/eig_recover << !\n');
fprintf(fid,'%s\n',eigfile);
fprintf(fid,'%u\n',l_last);
fprintf(fid,'!\n');
%
fclose(fid);

end




