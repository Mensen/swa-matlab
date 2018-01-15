function Info = swa_getInfoDefaults(Info, type, method)
% Get the current default detection parameters for slow waves (SW), spindles
% (SS), or saw-tooth waves (ST)

% 'method' input is only used for slow wave detection where there are distinct
% defaults for the envelope and "massimini detection criteria" ('mdc');

% check inputs
if nargin < 3
    method = 'envelope';
end

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
        Info.Parameters.Ref_Method = []; % canonical wave method ('envelope', 'diamond', 'midline', etc)
        Info.Parameters.Ref_Electrodes = false; % logical array of electrodes used for each canonical
        Info.Parameters.Ref_InspectionPoint = 'MNP'; % 'MNP'/'ZC'
        Info.Parameters.Ref_UseInside = 1; % 0/1 Use interior head channels or all
        Info.Parameters.Ref_UseStages = []; % whether or not to use sleep scoring information
        Info.Parameters.Ref_AmplitudeCriteria = 'relative'; % relative/absolute
        Info.Parameters.Ref_AmplitudeRelative = 5;         % Standard deviations from mean negativity
        Info.Parameters.Ref_AmplitudeAbsolute = 60;
        Info.Parameters.Ref_AmplitudeMax = 250; % maximum amplitude in case of artefacts
        Info.Parameters.Ref_WaveLength = [0.25 1.25];      % Length criteria between zero crossings
        Info.Parameters.Ref_SlopeMin = 0.90;             % Percentage cut-off for slopes
        Info.Parameters.Ref_Peak2Peak = [];               % Only for channel thresholding

        % channel detection
        % ^^^^^^^^^^^^^^^^^        
        Info.Parameters.Channels_Correlate2 = 'mean'; % which canonical wave (main, mean, or all)
        Info.Parameters.Channels_Detection = 'correlation'; % correlation/threshold
        Info.Parameters.Channels_Threshold = 0.9;             % amount to adjust threshold if using threshold method
        Info.Parameters.Channels_ClusterTest = true;
        Info.Parameters.Channels_WinSize = 0.100;

        % travelling parameters
        % ^^^^^^^^^^^^^^^^^^^^^        
        Info.Parameters.Travelling_GS = 40; % size of interpolation grid
        Info.Parameters.Travelling_MinDelay = 40; % minimum travel time (ms)
        Info.Parameters.Travelling_RecalculateDelay = true; % set to false if delay maps are manually calculated outside of algorith (e.g. smoothing)

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
                Info.Parameters.Ref_Method = 'diamond';
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
        Info.Parameters.Ref_Electrodes = []; % logical array of electrodes used for each canonical
        Info.Parameters.Filter_Apply = false; % No filter needed for CWT method...

        % Wavelet Parameters for Detection
        Info.Parameters.CWT_hPass = 2;
        Info.Parameters.CWT_lPass = 5;

        Info.Parameters.CWT_StdThresh = 1.75;    % Explore defaults
        Info.Parameters.CWT_AmpThresh = [];
        Info.Parameters.CWT_ThetaAlpha = 1.2;
        
        Info.Parameters.Burst_Length = 1;       % Maximum time between waves in seconds
        Info.Parameters.Burst_Adjust = 0.75; % Adjust the criteria for wave if found in a burst
        
        Info.Parameters.Channels_WinSize = 0.060; % in seconds
        Info.Parameters.Channel_Adjust = 0.9;

        Info.Parameters.Travelling_GS = 40; % Gridsize for delay map
        Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms
        
    case 'SS'
        
        % Reference / Canonical Parameters
        Info.Parameters.Ref_Method      = 'Midline';
        Info.Parameters.Ref_Electrodes = []; % logical array of electrodes used for each canonical
        Info.Parameters.Filter_Apply    = false; % No filter needed for CWT method...
        Info.Parameters.Ref_UseStages = []; % whether or not to use sleep scoring information
            
        % Filter Parameters
        Info.Parameters.Filter_Method = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
        Info.Parameters.Filter_band = [10, 16];
        Info.Parameters.Filter_checkrange = 2;
        Info.Parameters.Filter_Window = 0.150; % length of smoothing window for root mean square of power
        Info.Parameters.Filter_order = 2;

        Info.Parameters.Wavelet_name = 'fbsp1-1-3'; % b-spline wavelet; else use 'morl'
        Info.Parameters.Wavelet_norm = 1; % normalise according to median entire time coefficients
        
        % Spindle Criteria       
        Info.Parameters.Ref_AmplitudeCriteria = 'relative'; % relative/absolute
        Info.Parameters.Ref_AmplitudeMetric = 'median';
        Info.Parameters.Ref_AmplitudeRelative = [4, 2];  % Standard deviations from mean negativity [high, low]
        Info.Parameters.Ref_AmplitudeAbsolute = 15;
        Info.Parameters.Ref_NeighbourRatio = 3; % minimum tolerance for spindle/neighbour power ratio
        
        Info.Parameters.Ref_WaveLength = [0.3 3]; % time above threshold power
        Info.Parameters.Ref_MinWaves = 3; % minimum number of spindle waves
               
        Info.Parameters.Channels_Method = 'power'; % wavelet or power (FFT) method
        Info.Parameters.Channels_WinSize = 0.150; % window around ref spindle to search around (in seconds)
        Info.Parameters.Channels_Threshold = 0.75; % adjustment to ref criteria
        
end
