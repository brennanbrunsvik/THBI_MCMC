function plot_progress_chain(absTimeIter, par, accept_info, ptb); 

warning('plot_progress_chain not in use: use plot_progress_chain2.m'); 

if any(par.ii==[10 100 500 1000]) || (mod(par.ii, 1000) == 0) % Every thousand iterations or a few select iterations before that
    ifaccept           = [accept_info.ifaccept      ]; 
    loglik             = [accept_info.log_likelihood]; 
    ptbnorm            = [accept_info.ptbnorm       ]; 
    iter               = [accept_info.iter          ]; 
    
    nRow = 4; nCol = 1; 
    figure(3001); clf; hold on; set(gcf, 'color', 'white');
    
    subplot(nRow, nCol, 1); hold on; box on; 
    scatter([absTimeIter.data], iter); 
    xlabel('Time'); 
    title('Iteration'); 
    
    subplot(nRow, nCol, 2); hold on; box on; 
    scatter(iter, ifaccept); 
    xlabel('Iteration'); 
    title('Accepted or not'); 
    
    subplot(nRow, nCol, 3); hold on; box on; 
    scatter(iter, loglik); 
    xlabel('Time'); 
    title('Log likelihood'); 
    
    subplot(nRow, nCol, 4); hold on; box on; 
    scatter(iter, ptbnorm); 
    xlabel('Time'); 
    title('Norm of model change since last kernel reset');        
    
    exportgraphics(gcf, sprintf('%s/progress_%s.pdf',...
        par.res.resdir, par.res.chainID)); 
    
    
    % Something about which perturbation happened. 
    ptbs = string(ptb); 
    [all_ptb, first_occurance, ptb_num] = unique(ptbs); 
    
    figure(3002); set(gcf, 'pos', [719 711 1481 1346]); 
    clf; hold on; box on; grid on; 
    for i_allptb = [1:length(all_ptb)]; 
        scatter(find(ptb_num == i_allptb), i_allptb, 80, 'k', 'filled')
    end
    yticks([1:length(all_ptb)]); 
    yticklabels(all_ptb); 
    
    did_accept = ifaccept == 1; 
    scatter(find( did_accept), 0.5, 40, 'blue', 'filled')
    scatter(find(~did_accept), 0,   40, 'red' , 'filled')
    xlabel('Iteration'); 
    
    exportgraphics(gcf, sprintf('%s/progress_ptb_%s.pdf',...
        par.res.resdir, par.res.chainID)); 
    
end   

end