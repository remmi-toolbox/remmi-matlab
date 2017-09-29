function mtirSet = qmt(dset,varargin)
% mtirSet = remmi.ir.qmt(dset,name,init) performs MTIR analysis on 
% the data in dset: 
%
%       dset.(name) = data to process
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set including ti & td. 
%       dset.labels = cell array of labels to dset.img dimensions
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%
%       name = name of field in dset to fit. Default is 'img'
%       init = inital values and lower & upper bounds used for fitting
% 
%   Returns a data set containing mtir parameter maps of M0a, M0b, BPF, PSR, 
%   kmf, T1 & confidence interavls.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% load in the dataset

[name,init] = setoptions(varargin{:});

if ~exist('dset','var')
    dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name))
    dset = remmi.util.thresholdmask(remmi.recon(dset));
end

sz = size(dset.(name)); 

% what dimension is MT encoding?
mtDim = ismember(dset.labels,'IR');

if ~any(mtDim)
    error('Data set does not contain multiple inversion times');
end

% load in the needed parameters
ti = dset.pars.ti; % sec
td = dset.pars.td; % sec

if numel(ti)<6
    error('There are not enough inversion times in this datatset for MTIR analysis')
end

if numel(ti) ~= sz(mtDim)
    error('The number of inversion times does not match the dataset dimenions')
end

% define a mask if one is not given
if isfield(dset,'mask')
    mask = squeeze(dset.mask);
    
    % apply the mask across all non-MT dimensions
    mask = bsxfun(@times,mask,ones(sz(~mtDim)));
else
    mask = squeeze(true(sz(~mtDim)));
end

% initialize the mtir dataset
mtirSet.M0a = zeros(size(mask));
mtirSet.M0b = zeros(size(mask));
mtirSet.PSR = zeros(size(mask));
mtirSet.BPF = zeros(size(mask));
mtirSet.kmf = zeros(size(mask));
mtirSet.T1 = zeros(size(mask));
mtirSet.nrmse = zeros(size(mask));
mtirSet.inv_eff = zeros(size(mask));
mtirSet.ci = cell(size(mask));

tot_evals = sum(mask(:));
evals = 0;

% make the MT dimension the first index. 
idx = 1:ndims(dset.(name));
data = permute(dset.(name),[idx(mtDim) idx(~mtDim)]);

warning('off','MATLAB:singularMatrix')

fprintf('%3.0f %% done...',0);
for n=1:numel(mask)
    if mask(n)

        sig = squeeze(abs(data(:,n)));

        % initial guess & bounds
        b0 = init.b0(sig);
        lb = init.lb(sig);
        ub = init.ub(sig);

        % fit the data
        opts = optimset('display','off');
        [b,~,res,~,~,~,jac] = lsqnonlin(@(x) remmi.ir.sir(x,ti',td)-sig,b0,lb,ub,opts);

        % load the dataset
        mtirSet.M0a(n)=b(1);
        mtirSet.M0b(n)=b(2);
        mtirSet.PSR(n)=b(2)/b(1);
        mtirSet.BPF(n)=b(2)/(b(2)+b(1));
        mtirSet.kmf(n)=b(3);
        mtirSet.T1(n)=1/b(4);
        mtirSet.inv_eff(n)=b(5);
        mtirSet.nrmse(n) = norm(res)/norm(sig);

        % save confidence intervals on the original parameters
        mtirSet.ci{n} = nlparci(b,res,'jacobian',jac); 

        evals = evals+1;
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
    end
end
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);

warning('on','MATLAB:singularMatrix')

end

function [name,init] = setoptions(name,init)

if ~exist('name','var') || isempty(name)
    name = 'img';
end

if ~exist('init','var') || isempty(init)
    init.b0 = str2func('@(sig) [max(sig), max(sig)/10,  50,   2, -0.9]');
    init.lb = str2func('@(sig) [       0,           0,   2,   0,  -1]');
    init.ub = str2func('@(sig) [     inf,         inf, 200, inf,   1]');
end

end