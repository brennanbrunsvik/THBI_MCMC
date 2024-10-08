function [HK_A, HK_H, HK_K] = HKstack_anis_wrapper(par, model, ...
                                    RF, tt, rayp, options)  
    arguments
        par % Eventually contain phase weights
        model % Model structure
        RF,
        tt,
        rayp, 
        options.ifplot = false; 
        options.phase_wts = [.5, .3, .2]; % brb2022.02.08 1/3 for each gave h-kappa stacks that don't look like others... They had way to tight of constraint on moho depth (for synthetics). I'm making a compromise. 
        options.hBounds = [10, 70]; 
        options.kBounds = [1.5, 2.1]; 
        options.kNum = 201; % kNum ~= hNum to help catch errors. 
        options.hNum = 200; 
        options.posterior = []
    end

% MCMC/THBI wrapper to get relevant model/data and use it for radially 
% anisotropic HK stack. 

% Choose weighting for different phases. There are a few valid choices.
phase_wts = options.phase_wts; 

% Get average crust velocity. There are again a few choices. 
% Get vsv, vpv. If there is anisotropy, this influences HK calculation.
isCrust = model.z < model.zmoh; 
rho = mean(model.rho(isCrust)); % Medium density of crust. Not sure how best to average this yet.
eta = 1; % IMPORTANT if eta is ever not 1, we need to modify the code. 
vsAv = (1./mean(1./model.VS(isCrust)) + mean(model.VS(isCrust)) ) / 2; % mean VS. Decide which type of mean to take later. 
if isempty(options.posterior); % Have to calculate averages from 1-D profile. 
    xi = model.Sanis(isCrust)/100+1; % Radial S anisotropy. add one because for some reason here anisotropy is + or -
    xi = (1/mean(1./xi) + mean(xi)) / 2; % Voigt-Reuss-Hill average
    phi = model.Panis(isCrust)/100+1; % Radial P anisotropy
    phi = (1/mean(1./phi) + mean(phi)) / 2; 
else % If we have the posterior, get average values from there. 
    posterior = options.posterior; 
    xi = median(posterior.xicrust); 
    phi = median(posterior.phicrust); 
end
    
% Assume ray path change is insignificant when adding anisotropy
incAngVs = rayp2inc(rayp/111.1949, vsAv             ); 
incAngVp = rayp2inc(rayp/111.1949, vsAv * model.vpvs); % PN 20.6 was the incidence angle here. Seems reasonable. Same as for the real rays for US.CEH

[velVs,~] = christof_radial_anis(vsAv, vsAv * model.vpvs,...
    xi, phi, eta, rho, incAngVs); % Velocities for ray with vs incidence angle
[velVp,~] = christof_radial_anis(vsAv, vsAv * model.vpvs,...
    xi, phi, eta, rho, incAngVp); % Velocities for ray with vp incidence angle
vsvAn = velVs(2); % Vsv for s ray 
vpAn  = velVp(1); % Vp for p ray

% fprintf('\nvsvAn = %1.5f : vpAn = %1.5f\n', vsvAn, vpAn)

vpvsEffective = vpAn/vsvAn; 

[HK_A, HK_H, HK_K] = HKstack(RF, tt, ...
    rayp/111.1949, phase_wts, ...
    vsAv, ...
    linspace(options.hBounds(1), options.hBounds(2), options.hNum)',...
    linspace(options.kBounds(1), options.kBounds(2), options.kNum), ...
    'vpvsANIS_vpvs',vpvsEffective/model.vpvs,'Vsv_av',vsvAn); 

% The rest of the script expects transposed hk stack. For IRIS ears data loaded from Zach's functions, K is first dimension, H is second bb2021.12.31
HK_A = HK_A'; 
HK_H = HK_H'; 
HK_K = HK_K'; 


if options.ifplot; 
    figure(198); clf; hold on; set(gcf,'color','white');
    subplot(1,1,1); hold on; 
    xlabel('kappa'); ylabel('H'); title('Synthetic H-kappa stack'); 
    set(gca, 'ydir', 'reverse');         
    sf = pcolor(HK_K, HK_H, HK_A'); %Can't use surf. It's 3d. It always covers other plotting objects. 
    sf.EdgeAlpha = 0; 
    colorbar(); 
    xlim([min(HK_K), max(HK_K)]); 
    ylim([min(HK_H), max(HK_H)]); 


    % An unfinished attempt to interpolate to find the exact point of maximum h-k energy. 
%         F = griddedInterpolant({HK_K, HK_H},HK_A,'spline');
%         HK_K2 = linspace(min(HK_K)+.1, max(HK_K)-.1, 1000); 
%         HK_H2 = linspace(min(HK_H)+.1, max(HK_H)-.1, 1001); 
%         [HK_K2, HK_H2] = ndgrid(HK_K2, HK_H2); 
%         HK_A2 = F(HK_K2, HK_H2); 
%         Emax = max(max(HK_A2));
%         [xmax,ymax] = find(Emax==HK_A2); 
%         scatter(gca, HK_K2(xmax), HK_H2(ymax), 50, 'red')

    % Simple wasy to estimate maximum h-k energy point. 
    Emax = max(max(HK_A));
    [xmax,ymax] = find(Emax==HK_A); 
    kBest = HK_K(xmax); 
    hBest = HK_H(ymax); 

    % Plot position of max energy. 
    scatter(gca, kBest, hBest, 50, 'red')
    text(kBest, hBest, sprintf('H = %2.2f, k = %1.3f',...
        HK_H(ymax),HK_K(xmax)), 'verticalalignment', 'bottom' )

    % Plot true position of max energy. TODO add to legend. 
    scatter(model.crustmparm.vpvs, model.zmoh, 50, 'k'); 

    % Plot the receiver function and the predicted times of different phases. This is a function in HKstack.m 
    HKstack(RF, tt, ...
        rayp/111.1949, phase_wts, vsAv, ... 
        linspace(10, 70, 2000)',linspace(1.5, 2.1, 2001), ...
            'plotPicks',true,'kChoice',kBest,'hChoice',hBest, ...
            'vpvsANIS_vpvs',vpvsEffective/model.vpvs,'Vsv_av',vsvAn); 
end

end