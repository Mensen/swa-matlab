function swa_runICA(filename)

% load the file
EEG=pop_loadset(filename)

% check for average reference
if strcmp(EEG.ref, 'averef)
    averageReference = true;
else
    averageReference = false;
end

% rereference to a single channel
%if averageReference
%    EEG = pop_reref( EEG, [],...
%    'refloc', EEG.chaninfo.nodatchans(:));
%end

% run the ICA
EEG = pop_runica(EEG, 'extended', 1, 'interupt', 'off');

% rereference to average again
%if averageReference
%    EEG = pop_reref( EEG, [],...
%    'refloc', EEG.chaninfo.nodatchans(:));
%end
