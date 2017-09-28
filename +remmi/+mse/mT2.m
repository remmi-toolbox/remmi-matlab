function t2set = mT2(dset,varargin)

% update metrics and fitting with default options
[metrics,fitting,analysis,name] = remmi.mse.mT2options(varargin{:});

if ~isfield(dset,name) || isempty(dset.(name))
    dset = remmi.util.thresholdmask(remmi.recon(dset));
end

t2set = remmi.mse.analysis(dset,metrics,fitting,analysis,name);

end