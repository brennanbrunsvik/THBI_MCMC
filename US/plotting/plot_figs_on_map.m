%% Startup. Path definitions
clc; clear; 
run('../../a0_STARTUP_BAYES.m');
addpath('~/MATLAB/borders');
%%
resdir_computer = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_pod'; % /Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_eri/cont_EProt-s1m1m2_testnwk_dat0/low_noise_sp
% resdir_fig = '/Users/brennanbrunsvik/Documents/temp'; 
prior_path  = '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/ENAM/prior.mat' ; 
fstainfo = '/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/US/INFO/stations.mat';

% stamp = 'eus_mantle_anis'; 
% stamp = 'no_anis_mant'; 
% stamp = 'less_anis'; 
stamps = {'eus_mantle_anis','eus_no_mant_anis','no_anis_mant','less_anis',};
stamps = {'eus_no_mant_anis'};


% figname = 'heatmap_of_models.pdf'; 
% figname = 'final_true_vs_pred_data_wavs.png'; 
% figname = 'final_model.pdf'; 
fignames = {'heatmap_of_models.pdf', 'final_true_vs_pred_data_wavs.png', 'final_model.pdf'}; 

for istamp = 1:length(stamps); 
for ifigname = 1:length(fignames); 
    figname = fignames{ifigname}; 
    stamp = stamps{istamp}; 

    if strcmp('eus_mantle_anis', stamp);
        resdir_computer = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_pod'; 
    elseif strcmp('eus_no_mant_anis', stamp); 
        resdir_computer = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_collate'; 
    elseif strcmp('less_anis', stamp); 
        resdir_computer = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_cnsi';  
    elseif strcmp('no_anis_mant', stamp); 
        resdir_computer = '/Volumes/extDrive/offload/Users/brennanbrunsvik/Documents/UCSB/ENAM/THBI_ENAM/data/STASinv_cnsi';  
    end

    
    stainfo = load(fstainfo); 
    stainfo = stainfo.stainfo; 
    stalats = stainfo.slats; 
    stalons = stainfo.slons; 
    
    netall = string(stainfo.nwk); 
    staall = string(stainfo.stas); 
    
    
    figure(1); clf; hold on; 
    ax1 = gca(); 
    
    if contains(stamp, 'eus'); 
        xlimits = [-88, -73]; 
        ylimits = [30, 45]; 
    else; 
        xlimits = [-130, -100]; 
        ylimits = [30, 45]; 
    end
    xlim(xlimits); 
    ylim(ylimits); 
    
    [latbord, lonbord] = borders('states'); % add states map
    for iline = 1:length(latbord); 
        line(lonbord{iline}, latbord{iline}, 'color', 'k'); 
    end
    % for iplace = 1:length(lonbord); 
    %     m_line(lonbord{iplace}, latbord{iplace}, 'LineWidth',1,'color',0*[1 1 1])
    % end
    
    % Loop through each folder
    folds = dir(resdir_computer); 
    for i = 1:length(folds)
        if folds(i).isdir && ~ismember(folds(i).name, {'.', '..'})
            
            % Get station name etc if we have a result here. 
            name = folds(i).name;
            fold = sprintf('%s/%s/%s',resdir_computer, name, stamp); 
            if ~ exist(sprintf('%s/final_model.mat',fold)); 
                continue
            end
            splt = split(name, '_'); 
            sta = splt{1}; 
            net = splt{2}; 
            
            % 
            iallsta = find((sta == staall) & (net == netall)); 
            if length(iallsta) == 0; 
                continue
            end 
    
            lat = stalats(iallsta); 
            lon = stalons(iallsta); 
    
            fig_model = sprintf('%s/%s',fold,figname); % final_true_vs_pred_data_wavs.png
    
            if contains(figname, '.pdf'); 
                img_model = PDFtoImg(fig_model); 
                make_copy = true; 
            else
                img_model = fig_model; 
                make_copy = false; 
            end 
    
            if exist(img_model, 'file')
                % Insert the image at specified location
                img = imread(img_model);
                [img_height, img_width, ~] = size(img);
                
                % Define the position and size for the image
                img_pos_x = (lon-xlimits(1))/diff(xlimits); % lon;  % X position (longitude)
                img_pos_y = (lat-ylimits(1))/diff(ylimits); % lat;  % Y position (latitude)
                img_width_scaled = 0.05;  % Scaled width
                img_height_scaled = (img_height / img_width) * img_width_scaled;  % Scaled height based on aspect ratio
                
                % Insert the image
                ax = axes('Position', [img_pos_x, img_pos_y, img_width_scaled, img_height_scaled]);
                hold on ;
                imshow(img);
    
                % axes(ax1); 
                % scatter(lon, lat, 1, 'k', 'filled'); 
                % text(lon, lat, sprintf('%1.2f, %1.2f', lon, lat), 'Units','data', 'FontSize',4); 
    
                % scatter(ax, 0, 0, 1, 'k', 'filled', 'Units', 'normalized'); 
                text(ax, 0, .1, sprintf('%s %s %1.3f, %1.3f', net, sta, lon, lat), 'FontSize',0.5, 'Units','normalized'); 
                % break
            end
    
            if make_copy; 
                delete(img_model); 
            end 
    
    
        end
    end
    
    if ~exist(stamp, 'dir'); 
        mkdir(stamp); 
    end 
    
    exportgraphics(gcf, sprintf('./%s/%s.pdf',stamp,figname), 'Resolution',2400, 'ContentType','image'); 
end
end