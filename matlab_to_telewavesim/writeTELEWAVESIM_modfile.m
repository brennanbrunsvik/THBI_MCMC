function writeTELEWAVESIM_modfile(LAYmodel, modfile); 
% load('example_input.mat'); 

% Function to write LAYmodel in the format that telewavesim can work with
% to make receiver functions. 


dataStr = ''; % Initialize an empty string to hold the data

% Loop through each layer and concatenate to a string in the format needed for telewavesim. 
nlay = length(LAYmodel.zlayt); 
for i = 1:nlay; 
    thickness = LAYmodel.zlayb(i) - LAYmodel.zlayt(i); % Calculate layer thickness
    density = LAYmodel.rho(i); % Layer density
    Vp = LAYmodel.Vp(i); % P-wave velocity
    Vs = LAYmodel.Vs(i); % S-wave velocity
    transAnisotropy = LAYmodel.xi(i); % Transverse anisotropy from xi
    % TODO might have to convert from xi to a value centered at 0. 

    % Handle units. 
    density = density * 1000; 

    [vsv, vsh] = VsvVsh_from_VsXi(Vs, transAnisotropy); 
    transAnisotropy = (vsv-vsh)/Vs*100; % This follows the format assumed in telewavesim. See the function set_tri_tensor in utils.py for more info. 
    
    % Determine the anisotropy flag based on xi value. Assuming 'iso' for isotropic (xi=0) and 'tri' for any non-zero xi value
    if transAnisotropy == 0 
        layerFlag = 'iso';
    else
        layerFlag = 'tri';
    end
    
    % Trend and plunge are kept at zero for now. 
    trend = 0; % Trend of symmetry axis
    plunge = 90; % Plunge of symmetry axis
    
    % Format the current layer's data and concatenate it to the data string
    dataStr = [dataStr, sprintf('%f\t%f\t%f\t%f\t%s\t%f\t%f\t%f\n', ...
        thickness, density, Vp, Vs, layerFlag, transAnisotropy, trend, plunge)];
end

% Open a file for writing
fid = fopen(modfile, 'w');

% Write the data string to the file in one go
fprintf(fid, '%s', dataStr);

% Close the file
fclose(fid);

end