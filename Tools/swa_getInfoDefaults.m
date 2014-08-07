function Info = swa_getInfoDefaults(Info, type, method)

switch type
    case 'SW'
        % filter parameters
        Info.Parameters.Filter_Apply    = [];
        Info.Parameters.Filter_Method   = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
        Info.Parameters.Filter_hPass    = 0.2;
        Info.Parameters.Filter_lPass    = 4;
        Info.Parameters.Filter_order    = 2;
        
        % reference detection
        Info.Parameters.Ref_Method      = [];
        Info.Parameters.Ref_ZCorMNP     = 'MNP';
        Info.Parameters.Ref_UseInside   = 1;                % Use interior head channels or all
        Info.Parameters.Ref_AmpStd      = 4.5;              % Standard deviations from mean negativity
        Info.Parameters.Ref_NegAmpMin   = 80;               % Only used if Ref_AmpStd not set
        Info.Parameters.Ref_WaveLength  = [0.25 1.25];      % Length criteria between zero crossings
        Info.Parameters.Ref_SlopeMin    = 0.90;             % Percentage cut-off for slopes
        Info.Parameters.Ref_Peak2Peak   = [];               % Only for MDC
        
        % channel detection
        Info.Parameters.Channels_CorrThresh = 0.9;
        Info.Parameters.Channels_WinSize    = 0.2;
        
        % travelling parameters
        Info.Parameters.Stream_GS       = 40; % size of interpolation grid
        Info.Parameters.Stream_MinDelay = 40; % minimum travel time (ms)
        
        if isempty(method)
            method = 'envelope';
        end
        
        switch lower(method)
            case 'envelope'    
                % set envelope specific defaults
                Info.Parameters.Ref_Method      = 'Envelope';
                Info.Parameters.Filter_Apply    = true;
                
            case 'mdc'
                Info.Parameters.Ref_Method      = 'MDC';
                Info.Parameters.Ref_Peak2Peak   = 140;
        end
       
end