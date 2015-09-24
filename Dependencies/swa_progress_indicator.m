function swa_progress_indicator(type, current, maximum)
% command line progress bar that erases past progress

% usage:
% swa_progress_indicator('initialise', 'percentage complete')
% 
% for n = 1:30
%    
%     WaitSecs(0.1);
%     
%     swa_progress_indicator('update', n, 30);
%     
% end


switch type
    
    case {'initialise', 'initialize'}
        
        fprintf(1, ['\n', current, ': 00.00 %%']);
        
    case 'update'
   
        percentage = current / maximum * 100;
        
        if ~(percentage > 10)
            
            fprintf(1, '\b\b\b\b\b\b\b\b 0%.2f %%', percentage);

        else
            
            fprintf(1, '\b\b\b\b\b\b\b\b %.2f %%', percentage);
            
        end
   
        if current == maximum
            
            fprintf(1, '\n');
            
        end
        
end