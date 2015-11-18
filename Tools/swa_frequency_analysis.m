function data_out = swa_frequency_analysis(data_in, e_loc, varargin)
% calculate and plot the scalp topography of specified frequency bands

% usage
% ^^^^^
% data_in   = EEG.data(1,1:10000);
% srate     = EEG.srate;
% output    = swa_frequency_analysis(EEG.data, EEG.chanlocs, 'srate', EEG.srate);

% optional input handling
% ^^^^^^^^^^^^^^^^^^^^^^^
% default options
options = struct(...
    'srate',            200,...
    'method',           'pwelch',...
    'plots',            true,...
    'bad_channels',     [ ],...
    'bands',            [0,   4 ;
                         5,   8 ;
                         8,  12 ;
                         12, 16 ;
                         16, 25 ]);

% read the acceptable names
optionNames = fieldnames(options);

% count arguments
nArgs = length(varargin);
if round(nArgs/2)~=nArgs/2
   error('optional inputs are propertyName/propertyValue pairs')
end

for pair = reshape(varargin,2,[]) %# pair is {propName;propValue}
   inpName = lower(pair{1}); %# make case insensitive

   if any(strncmp(inpName, optionNames, length(inpName)))
      options.(inpName) = pair{2};
   else
      fprintf(1, '%s is not a recognized parameter name, ignoring...\n', inpName);
   end
end
   

% compute the power spectrum density
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
switch options.method
    % use the simple fast fourier transform of the whole data
    case 'fft'
        % calculate the frequency range
        freq_range  = options.srate/2*linspace(0,1,options.srate/2);
        
        % calculate the fast fourier transform (and normalise by number of samples)
        data_fft    = fft(data_in, options.srate, 2) / size(data_in, 2);
        
        % use only single sided absolute values of the spectrum
        data_fft    = abs(data_fft(:, 1:options.srate/2));
    
    % estimate using the pwelch estimate (average of overlapping segments)
    case 'pwelch'
        % TODO: pwelch method
        % pre-allocate
        data_fft = zeros(options.srate/2+1, size(data_in, 1));
        for n = 1:size(data_in, 1)
            [data_fft(:, n), freq_range] = pwelch(...
                data_in(n,:)    ,...
                []              ,...
                []              ,...
                options.srate   ,...
                options.srate   ,...
                'onesided'      );
        end
        data_fft = data_fft';
end

% calculate the parts of each band
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
% pre-allocate the range
number_bands = size(options.bands, 1);
data_out = zeros(size(data_fft, 1), number_bands);

% loop over each band and average the frequencies
    % TODO: may be optimal to normalise each band first (1/f);
for b = 1:number_bands
   range         = freq_range >= options.bands(b, 1) & freq_range <= options.bands(b, 2);
   data_out(:,b) = mean(data_fft(:, range), 2);
end

% separate topography for each band
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if options.plots
    % create the figure
    h.fig = figure(...
        'color', [0.1, 0.1, 0.2]    ,...
        'units', 'normalized'       ,...
        'position', [0 0.5, 1, 0.5] );
    
    % calculate multiple axes paramters
    % Determines the starting x-axis point for each plot
    axesPos     = (0:1:number_bands)/number_bands;
    axesWidth   = 1/number_bands;
    
    % create the axes and plot the topography on those axes
    for b = 1:number_bands
        % axes creation
        h.ax(b) = axes(...
            'parent'    , h.fig     ,...
            'position'  , [axesPos(b) 0 axesWidth 1] ,...
            'xtick'     , [] ,...
            'ytick'     , [] );
        
        % topoplot creation
        h.topoplots(b) = swa_Topoplot( [] , e_loc               ,...
            'Data',             data_out(:,b)                       ,...
            'GS',               40                                  ,...
            'NewFigure',        0                                   ,...
            'Axes',             h.ax(b)                             ,...
            'NumContours',      4                                   ,...
            'PlotSurface',      1                                   );
        
        % plot titles
        % uses latex for text only because linux has some issues with the
        % the classic figure renderer
        h.titles(b) = title(h.ax(b),...
            [int2str(options.bands(b,1)), 'Hz to ', int2str(options.bands(b,2)), 'Hz'],...
            'color', [0.9, 0.9, 0.9],...
            'fontSize', 30,...
            'interpreter', 'latex');
        
    end
end

