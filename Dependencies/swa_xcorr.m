function [R] = swa_xcorr(refData, shortData, win)
% function to analyse the cross correlation between the reference channel
% and all subsequent channels using a sliding window without zero padding

R = zeros(size(shortData,1), win*2+1);
for t = 1:win*2+1
    R(:,t) = corr(refData',shortData(:,t:t+size(refData,2)-1)');
end