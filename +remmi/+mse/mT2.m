function t2set = mT2(dset,varargin)
%   t2set = remmi.mse.mT2(dset,metrics,fitting,mera_analysis,name) 
%   performs multi-exponential T2 analysis on data in dset.
%
%       dset.(name) = data to process
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set including te
%       dset.labels = cell array of labels to dset.img dimensions
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%
%       metrics = a optional structure of function handles that operate on 
%       the output structure of MERA. 
%
%       fitting & mera_analysis = passed directly to MERA for multi- 
%       exponential T2/EPG analysis
%
%       name = name of field in dset to fit. Default is 'img'
%
%   Defaults values for metrics, fitting, mera_analysis, and name can be  
%   found in the function remmi.mse.mT2options();
%
%   Returns a dataset which contains parameter maps defined in the metrics
%   structure
%
%   Kevin Harkins & Mark Does, Vanderbilt University
%   for the REMMI Toolbox


% update metrics and fitting with default options
[metrics,fitting,analysis,name] = remmi.mse.mT2options(varargin{:});

if ~isfield(dset,name) || isempty(dset.(name))
    disp('Using default mask') % alert user that default mask in use  
    dset = remmi.util.thresholdmask(remmi.recon(dset));
end

t2set = remmi.mse.analysis(dset,metrics,fitting,analysis,name);

end