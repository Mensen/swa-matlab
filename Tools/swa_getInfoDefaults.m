function Info = swa_getInfoDefaults(Info, type, method)

switch type
    case 'SW'
        % filter parameters
        % ^^^^^^^^^^^^^^^^^
        Info.Parameters.Filter_Apply = true;
        Info.Parameters.Filter_Method = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
        Info.Parameters.Filter_hPass = 0.5;
        Info.Parameters.Filter_lPass = 4;
        Info.Parameters.Filter_order = 2;

        % reference detection        
        % ^^^^^^^^^^^^^^^^^^^
        Info.Parameters.Ref_Method = [];
        Info.Parameters.Ref_InspectionPoint = 'MNP';    % 'MNP'/'ZC'
        Info.Parameters.Ref_UseInside = 1;                % 0/1 Use interior head channels or all
        Info.Parameters.Ref_UseStages = []; % whether or not to use sleep scoring information
        Info.Parameters.Ref_AmplitudeCriteria = 'relative'; % relative/absolute
        Info.Parameters.Ref_AmplitudeRelative = 5;         % Standard deviations from mean negativity
        Info.Parameters.Ref_AmplitudeAbsolute = 60;
        Info.Parameters.Ref_WaveLength = [0.25 1.25];      % Length criteria between zero crossings
        Info.Parameters.Ref_SlopeMin = 0.90;             % Percentage cut-off for slopes
        Info.Parameters.Ref_Peak2Peak = [];               % Only for channel thresholding

        % channel detection
        % ^^^^^^^^^^^^^^^^^        
        Info.Parameters.Channels_Detection = 'correlation'; % correlation/threshold
        Info.Parameters.Channels_Threshold = 0.9;             % amount to adjust threshold if using threshold method
        Info.Parameters.Channels_ClusterTest = true;
        Info.Parameters.Channels_WinSize = 0.10;

        % travelling parameters
        % ^^^^^^^^^^^^^^^^^^^^^        
        Info.Parameters.Travelling_GS = 40; % size of interpolation grid
        Info.Parameters.Travelling_MinDelay = 40; % minimum travel time (ms)

        % option specific defaults
        % ^^^^^^^^^^^^^^^^^^^^^^^^        
        if isempty(method)
            method = 'envelope';
        end

        switch lower(method)
            case 'envelope'
                % set envelope specific defaults
                Info.Parameters.Ref_Method = 'Envelope';

            case 'mdc'
                Info.Parameters.Ref_Method = 'MDC';
                Info.Parameters.Ref_AmplitudeCriteria = 'absolute';
                Info.Parameters.Ref_InspectionPoint = 'ZC';
                Info.Parameters.Ref_AmplitudeAbsolute = 80;
                Info.Parameters.Ref_Peak2Peak = 140;             % Only for channel thresholding
                Info.Parameters.Channels_Detection = 'threshold';     % correlation/threshold
                Info.Parameters.Channels_Threshold = 1;             % amount to adjust threshold if using threshold method

        end

    case 'ST'

        % Reference and Filter Parameters
        Info.Parameters.Ref_Method = 'Midline';
        Info.Parameters.Filter_Apply = false; % No filter needed for CWT method...

        % Wavelet Parameters for Detection
        Info.Parameters.CWT_hPass = 2;
        Info.Parameters.CWT_lPass = 5;

        Info.Parameters.CWT_StdThresh = 1.75;    % Explore defaults
        Info.Parameters.CWT_AmpThresh = [];
        Info.Parameters.CWT_ThetaAlpha = 1.2;
        Info.Parameters.Burst_Length = 1;       % Maximum time between waves in seconds

        Info.Parameters.Channels_WinSize = 0.060; % in seconds

        Info.Parameters.Travelling_GS = 40; % Gridsize for delay map
        Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms
        
    case 'SS'
        
        % Reference Parameters
        Info.Parameters.Ref_Method      = 'Midline';
        Info.Parameters.Filter_Apply    = false; % No filter needed for CWT method...
                
        % Filter Parameters
        Info.Parameters.Filter_Method = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
        Info.Parameters.Filter_hPass(1) = 11.5;
        Info.Parameters.Filter_lPass(1) = 14;
        Info.Parameters.Filter_hPass(2) = 14;
        Info.Parameters.Filter_lPass(2) = 16.5;
        Info.Parameters.Filter_Window = 0.150; % length of smoothing window for root mean square of power
        Info.Parameters.Filter_order = 2;

        
        % Spindle Criteria       
        Info.Parameters.Ref_AmplitudeCriteria = 'relative';  % relative/absolute
        Info.Parameters.Ref_AmplitudeRelative = 8;           % Standard deviations from mean negativity
        Info.Parameters.Ref_AmplitudeAbsolute = 15;
        
        Info.Parameters.Ref_WaveLength = [0.3 3];      % Length criteria between zero crossings
        Info.Parameters.Ref_MinWaves = 3;
               
        Info.Parameters.Channels_WinSize = 0.150; % in seconds
        Info.Parameters.Channels_Threshold = 0.75;
        
end
