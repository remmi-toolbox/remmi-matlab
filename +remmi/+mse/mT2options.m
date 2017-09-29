function [metrics,fitting,analysis,name] = mT2options(metrics,fitting,analysis,name)
% [metrics,fitting,analysis,name] = mT2options(metrics,fitting,analysis,name)
% sets default 
%

if ~exist('metrics','var') || isempty(metrics)
    % using str2func to suppress warnings when anonymous functions are
    % saved & re-loaded
    metrics.MWF  = str2func('@(out) sum(out.Fv.*(out.Tv>0.003 & out.Tv<.017),1)./sum(out.Fv,1)');
    metrics.gmT2 = @(out) calcGeometricMean(out);
    metrics.B1   = str2func('@(out) out.theta');
end

if ~exist('fitting','var') || isempty(fitting)
    fitting.regtyp = 'mc';
    fitting.regadj='manual';
    fitting.regweight=0.0005; 
    fitting.B1fit = 'y';
    fitting.rangetheta=[135 180];
    fitting.numbertheta=10;
    fitting.numberT = 100;
    fitting.rangeT = [0.005 .5];
end

if ~exist('analysis','var') || isempty(analysis)
    analysis.graph = 'n';
    analysis.interactive = 'n';
end

if ~exist('name','var') || isempty(name)
    name = 'img';
end

end

function gmT2 = calcGeometricMean(out)

lTv = log(out.Tv);
lTv(isinf(lTv)) = 0;

gmT2 = exp(sum(out.Fv.*lTv,1)./sum(out.Fv,1));

end