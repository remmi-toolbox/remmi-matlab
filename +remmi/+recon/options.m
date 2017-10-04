function opts = options(opts)
% opts = remmi.recon.options(opts) sets default reconstruction options
%
%       opts.apodize_fn = function to apodize fourier data
%       opts.matrix_sz  = matrix size for reconstruction
%
%   this function does not overwrite already set options
%

if ~exist('opts','var')
    opts = struct();
end

if ~isfield(opts,'apodize_fn') || isempty(opts.apodize_fn)
    opts.apodize_fn = str2func('@(x)remmi.util.apodize(x,0.25)');
end

if ~isfield(opts,'matrix_sz')
    opts.matrix_sz = [];
end