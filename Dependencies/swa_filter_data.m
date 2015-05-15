function filtData = swa_filter_data(data, Info)

% check for all parameters
if ~isfield(Info.Parameters, 'Filter_order')
    Info.Parameters.Filter_order = 2;
end

switch Info.Parameters.Filter_Method
    case 'Chebyshev'
        Wp=[Info.Parameters.Filter_hPass Info.Parameters.Filter_lPass]/(Info.Recording.sRate/2); % Filtering parameters
        Ws=[Info.Parameters.Filter_hPass/5 Info.Parameters.Filter_lPass*2]/(Info.Recording.sRate/2); % Filtering parameters
        Rp=3;
        Rs=10;
        [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs);
        [bbp,abp]=cheby2(n,Rs,Wn); % Loses no more than 3 dB in pass band and has at least 10 dB attenuation in stop band
        % fprintf(1, 'Filtering Reference Channel(s)...');
        filtData=filtfilt(bbp, abp, data')';
        % fprintf(1, 'Done. \n');
        
    case 'Buttersworth'
        fhc = Info.Parameters.Filter_hPass/(Info.Recording.sRate/2);
        flc = Info.Parameters.Filter_lPass/(Info.Recording.sRate/2);
        [b1,a1] = butter(Info.Parameters.Filter_order,fhc,'high');
        [b2,a2] = butter(Info.Parameters.Filter_order,flc,'low');
        
        % fprintf(1, 'Filtering Reference Channel(s)...');
        filtData = filtfilt(b1, a1, data');
        filtData = (filtfilt(b2, a2, filtData))';
        % fprintf(1, 'Done. \n');
end

