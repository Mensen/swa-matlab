function Info = swa_getInfoDefaults(Info, type, method)

switch type
    case 'SW'
        % filter parameters
        Info.Parameters.Filter_Apply    = true;
        Info.Parameters.Filter_Method   = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
        Info.Parameters.Filter_hPass    = 0.5;
        Info.Parameters.Filter_lPass    = 4;
        Info.Parameters.Filter_order    = 2;
        
        % reference detection
        Info.Parameters.Ref_Method      = [];
        Info.Parameters.Ref_ZCorMNP     = 'MNP';
        Info.Parameters.Ref_UseInside   = 1;                % Use interior head channels or all
        Info.Parameters.Ref_AmpStd      = 5;                % Standard deviations from mean negativity
        Info.Parameters.Ref_NegAmpMin   = 80;               % Only used if Ref_AmpStd not set
        Info.Parameters.Ref_WaveLength  = [0.25 1.25];      % Length criteria between zero crossings
        Info.Parameters.Ref_SlopeMin    = 0.90;             % Percentage cut-off for slopes
        Info.Parameters.Ref_Peak2Peak   = [];              % Only for channel thresholding
        
        % channel detection
        Info.Parameters.Channels_Method     = 'correlation'; % correlation/threshold
        Info.Parameters.Channels_AdjThresh  = 1;             % amount to adjust threshold if using threshold method
        Info.Parameters.Channels_CorrThresh = 0.90;
        Info.Parameters.Channels_WinSize    = 0.10;
        
        % travelling parameters
        Info.Parameters.Travelling_GS       = 40; % size of interpolation grid
        Info.Parameters.Travelling_MinDelay = 40; % minimum travel time (ms)
        
        if isempty(method)
            method = 'envelope';
        end
        
        switch lower(method)
            case 'envelope'    
                % set envelope specific defaults
                Info.Parameters.Ref_Method      = 'Envelope';
                
            case 'mdc'
                Info.Parameters.Ref_Method      = 'MDC';
                Info.Parameters.Ref_ZCorMNP     = 'ZC';
                Info.Parameters.Ref_Peak2Peak   = 140;             % Only for channel thresholding
                Info.Parameters.Ref_AmpStd      = [];              % Standard deviations from mean negativity
                Info.Parameters.Channels_Method = 'threshold';     % correlation/threshold
        end
       
    case 'ST'

        % Reference and Filter Parameters
        Info.Parameters.Ref_Method          = 'Midline';
        Info.Parameters.Filter_Apply        = false; % No filter needed for CWT method...
        
        % Wavelet Parameters for Detection
        Info.Parameters.CWT_hPass           = 2;
        Info.Parameters.CWT_lPass           = 5;
        
        Info.Parameters.CWT_StdThresh       = 1.75;    % Explore defaults
        Info.Parameters.CWT_AmpThresh       = [];
        Info.Parameters.CWT_ThetaAlpha      = 1.2;
        Info.Parameters.Burst_Length        = 1;       % Maximum time between waves in seconds
        
        Info.Parameters.Channels_WinSize    = 0.060; % in seconds
        
        Info.Parameters.Travelling_GS       = 40; % Gridsize for delay map
        Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms
end
