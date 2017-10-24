function opts = options(opts)
% opts = remmi.recon.options(opts) sets default reconstruction options
%
%       opts.apodize_fn = function to apodize fourier data
%       opts.matrix_sz  = matrix size for reconstruction
%
%   this function does not overwrite already set options
%
%  Kevin Harkins & Mark Does, Vanderbilt University
%  for the REMMI Toolbox

if ~exist('opts','var')
    opts = struct();
end

if ~isfield(opts,'apodize_fn') || isempty(opts.apodize_fn)
    % by default, no apodization...?
    opts.apodize_fn = str2func('@(x) x');
    
    %opts.apodize_fn = str2func('@(x)remmi.util.apodize(x,0.25)');
end

if ~isfield(opts,'matrix_sz')
    opts.matrix_sz = [];
end