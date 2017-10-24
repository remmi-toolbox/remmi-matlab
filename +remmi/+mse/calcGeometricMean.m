function gmT2 = calcGeometricMean(out)
% sig = remmi.mse.calcGeometricMean(out) calculates the geometric mean T2
% from a T2 spectrum
%
%   out = output from remmi.mse.MERA.MERA(...)
%
%   gmT2 = geometric mean T2
%
% example:
%   metrics.gmT2 = @remmi.mse.calcGeometricMean;
%   epg_struct = remmi.mse.mT2(img_struct,metrics);
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

lTv = log(out.Tv);
lTv(isinf(lTv)) = 0;

gmT2 = exp(sum(out.Fv.*lTv,1)./sum(out.Fv,1));

end