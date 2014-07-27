function swa_save_data(data, saveName)

% make sure the data is single precision to save space
data = single(data);

% create the file
fid = fopen(saveName, 'w');

% write the data to the file
fwrite (fid, data, 'single', 'l');

% close the file
fclose (fid);