% function [model1,Pm_prior1, ptb1, non_acceptk, p_bd] = delay_reject(...
%     non_acceptk, model, model1, Pm_prior, Pm_prior1, ptb, ii, ptb1, p_bdOrig); 

function [model1,ptbnorm,ifpass,p_bd,Pm_prior1,...
    ptb,modptb,nchain,breakTrue,non_acceptk]...
    = delay_reject(model, Pm_prior, ptb, ii, par, temp, Kbase,nchain,...
        model1,ptbnorm,p_bdOrig,Pm_prior1k,non_acceptk); 

plotTrue = false; % Set to true if you want to see how the models are changing according to delayed rejection.  
    
    
p_bd = p_bdOrig; 

% % % if non_acceptk > 0; % Decide if we perturb again, even though we are working with a failed perturbed model. 
% % %     toReset = rand(1) > 0.5; % If previous model failed, there is an X percent chance we perturb again
% % % elseif non_acceptk == 0; 
% % %     toReset = true; 
% % % end
% % %     
% % % if toReset; % We just accepted the last model. Definitely perturb from base model.  
% % %     [model1,ptbnorm,ifpass,p_bd,Pm_prior1,...
% % %         ptb,modptb,nchain,breakTrue]...
% % %         = perturb_model(model, Pm_prior, ptb, ii, par, temp, Kbase,nchain); 
% % %     non_acceptk = 1; 
% % %     
% % % elseif ~toReset; % We perturbed model and failed. Let's perturb one more time. 
% % %     [model2,ptbnormk,ifpass,p_bdk,Pm_prior1,...
% % %         ptb,modptb,nchain,breakTrue]...
% % %         = perturb_model(model1, Pm_prior, ptb, ii, par, temp, Kbase,nchain); 
% % %     % model1 is now perturbed twice. 
% % %     ptbnorm = ptbnormk + ptbnorm;  % Not sure what to do here yet. 
% % %     % ifpass no changing tI think
% % %     p_bd = p_bd * p_bdk;  % TODO get p_bd, probability for previous model bd. 
% % %     % Pm_prior SHould be fine. 
% % %     % ptb TODO decide what to do here. 
% % %     % modptb = modptb idk yet. 
% % %     % nchain, ? 
% % %     non_acceptk = non_acceptk + 1; 
% % %     
% % %     plotTrue = true; 
% % %     if plotTrue
% % %         figure(500); clf; hold on; 
% % %         LineWidth = 3; 
% % %         plot(model .VS, model .z, 'k',    'linewidth', LineWidth, 'Displayname', 'model base')
% % %         plot(model1.VS, model1.z, 'b--',  'linewidth', LineWidth, 'Displayname', 'model n-1')
% % %         plot(model2.VS, model2.z, 'r--',  'linewidth', LineWidth, 'Displayname', 'model n')
% % %         legend()    
% % %         xlabel('Vs'); 
% % %         ylabel('Depth'); 
% % %         set(gca, 'ydir', 'reverse'); 
% % %         title(sprintf('Perturbations 0, n-1, n (n=%1.0f)', non_acceptk))
% % %         grid on; 
% % %         box on; 
% % %         set(gcf, 'color', 'white')
% % %         sprintf('Did another perturbation at ii = %1.0f', ii)
% % %     end
    
    % % % 
% Below code is basic delayed rejection. Perturb once always if last model
% failed. Start from last successful model after that. 
if non_acceptk == 0; % We just accepted the last model. Definitely perturb from base model.  
    [model1,ptbnorm,ifpass,p_bd,Pm_prior1,...
        ptb,modptb,nchain,breakTrue]...
        = perturb_model(model, Pm_prior, ptb, ii, par, temp, Kbase,nchain); 
    non_acceptk = 1; 
    
    if plotTrue
        figure(500); clf; hold on; 
        LineWidth = 3; 
        plot(model .VS, model .z, 'k',    'linewidth', LineWidth, 'Displayname', 'model 0 (previous)')
        plot(model1.VS, model1.z, 'b--',  'linewidth', LineWidth, 'Displayname', 'model1')
        legend()    
        xlabel('Vs'); 
        ylabel('Depth'); 
        set(gca, 'ydir', 'reverse'); 
        title(['One perturbation from last accepted model \newline Iteration' sprintf('%5.0f',par.ii) ]);
        grid on; 
        box on; 
        set(gcf, 'color', 'white')
        xlim([2.8, 4.8]); 
    end
    
elseif non_acceptk == 1; % We perturbed model and failed. Let's perturb one more time. 
    [model2,ptbnormk,ifpass,p_bdk,Pm_prior1,...
        ptb,modptb,nchain,breakTrue]...
        = perturb_model(model1, Pm_prior, ptb, ii, par, temp, Kbase,nchain); 
    % model1 is now perturbed twice. 
    % However, we do NOT want to combine ptbnormk and ptbnorm. 
    % ptbnorm is calculated by comparing current model with kbase model. 
    % So it is already correct: ptbnormk is not necessary. 
%     ptbnorm = ptbnormk * ptbnorm;  < this would be wrong. 

    p_bd = p_bd * p_bdk;  % TODO get p_bd, probability for previous model bd. 
    % Pm_prior SHould be fine. 

    if plotTrue
        figure(500); clf; hold on; 
        LineWidth = 3; 
        plot(model .VS, model .z, 'k',    'linewidth', LineWidth, 'Displayname', 'model 0 (previous)')
        plot(model1.VS, model1.z, 'b--',  'linewidth', LineWidth, 'Displayname', 'model1')
        plot(model2.VS, model2.z, 'r.',  'linewidth', LineWidth, 'Displayname', 'model2')
        legend()    
        xlabel('Vs'); 
        ylabel('Depth'); 
        set(gca, 'ydir', 'reverse'); 
        title(['Perturbations 0, 1, 2 \newline Iteration ' sprintf('%5.0f',par.ii) ]);
        grid on; 
        box on; 
        set(gcf, 'color', 'white')
        sprintf('Did a second perturbation at ii = %1.0f', ii)
        xlim([2.8, 4.8]); 
    end
    
    non_acceptk = 2; 
    model1 = model2; 
        
elseif non_acceptk == 2; 
    [model1,ptbnorm,ifpass,p_bd,Pm_prior1,...
        ptb,modptb,nchain,breakTrue]...
        = perturb_model(model, Pm_prior, ptb, ii, par, temp, Kbase,nchain); 
    non_acceptk = 1; 
    
    if plotTrue
        figure(500); clf; hold on; 
        LineWidth = 3; 
        plot(model .VS, model .z, 'k',    'linewidth', LineWidth, 'Displayname', 'model 0 (previous)')
        plot(model1.VS, model1.z, 'b--',  'linewidth', LineWidth, 'Displayname', 'model1')
        legend()    
        xlabel('Vs'); 
        ylabel('Depth'); 
        set(gca, 'ydir', 'reverse'); 
        title(['2 perturbations failed. Now one perturbation from last accepted model\newline Iteration ' sprintf('%5.0f',par.ii) ]);
        grid on; 
        box on; 
        set(gcf, 'color', 'white')
        xlim([2.8, 4.8]); 
    end
    
end

if plotTrue; 
    exportgraphics(gcf, ['./temp_model_' num2str(par.ii) '.pdf']); 
end



end