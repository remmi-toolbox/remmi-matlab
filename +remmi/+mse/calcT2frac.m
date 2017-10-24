function frac = calcT2frac(out,lb,ub)
% sig = remmi.mse.calcT2frac(out,lb,ub) calculates a T2 signal fraction
%
%   out = output from remmi.mse.MERA.MERA(...)
%   lb,ub = lower and upper bounds on T2 peaks to include in the
%   calculation
%
%   frac = fraction of signal exhibiting T2s between lb and ub
%
% example:
%   metrics.MWF = @(out) remmi.mse.calcT2frac(out,0.005,0.020);
%   epg_struct = remmi.mse.mT2(img_struct,metrics);
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

frac = sum(out.Fv.*(out.Tv>lb&out.Tv<ub),1)./sum(out.Fv,1)';

end
