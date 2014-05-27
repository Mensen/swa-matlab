function [S,actfrq] = swa_frq2scal(frq,wname,delta)

logscale0 = 24:-1:-10;
F0 = scal2frq(2 .^ logscale0,wname,delta);

logscale = interp1(log2(F0),logscale0, log2(frq));
actfrq = scal2frq(round(2 .^ logscale),wname,delta);

S = round(2 .^ logscale);
