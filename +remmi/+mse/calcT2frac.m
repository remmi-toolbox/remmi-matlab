function frac = calcT2frac(out,lb,ub)
% sig = remmi.mse.calcT2frac(out,lb,ub) calculates a T2 signal fraction
%
%   out = output from remmi.mse.MERA.MERA()
%   lb,ub = lower and upper bounds on T2 peaks to include in the
%   calculation
%
%   frac = fraction of signal exhibiting T2s between lb and ub
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

frac = sum(out.Fv.*(out.Tv>lb&out.Tv<ub),1)./sum(out.Fv,1)';

end
