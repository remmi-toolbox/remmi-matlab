function irSet = T1(dset,varargin)
% irSet = remmi.ir.T1(dset,name) performs inversion recovery analysis on 
% the dataset: 
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
% 
%   Returns a data set containing ir parameter maps of M0, T1 (same units
%   as dset.pars.ti) and flip angle (degrees)
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

name = setoptions(varargin{:});

if ~exist('dset','var')
    dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name))
    dset = remmi.util.thresholdmask(remmi.recon(dset));
end

% load in the dataset
sz = size(dset.(name)); 

% what dimension is MT encoding?
irDim = ismember(dset.labels,'IR');

if ~any(irDim)
    error('Data set does not contain multiple inversion times');
end

% load in the needed parameters
ti = dset.pars.ti;
td = dset.pars.td;

if numel(ti)<3
    error('There are not enough inversion times in this datatset for IR analysis')
end

if numel(ti) ~= sz(irDim)
    error('The number of inversion times does not match the dataset dimenions')
end

% define a mask if one is not given
if isfield(dset,'mask')
    mask = squeeze(dset.mask);
else
    mask = squeeze(true(sz(~irDim)));
end

% initialize the mtir dataset
irSet.M0 = zeros(size(mask));
irSet.T1 = zeros(size(mask));
irSet.flip_angle = zeros(size(mask));
irSet.nrmse = zeros(size(mask));
irSet.ci = cell(size(mask));

tot_evals = sum(mask(:));
evals = 0;

% make the MT dimension the first index. 
idx = 1:numel(size(dset.(name)));
data = permute(dset.(name),[idx(irDim) idx(~irDim)]);

warning('off','MATLAB:singularMatrix')

t1fun = @(x) abs(remmi.ir.ir(x,ti(:),ti(:)+td));

fprintf('%3.0f %% done...',0);
for n=1:numel(mask)
    if mask(n)

        sig = squeeze(abs(data(:,n)));

        % initial guess & bounds
        b0 = [max(sig), 0.400, 150]; 
        lb = [       0,     0,   0];
        ub = [     inf,   inf, 180];

        % fit the data
        opts = optimset('display','off');
        [b,~,res,~,~,~,jac] = lsqnonlin(@(x) t1fun(x)-sig(:),b0,lb,ub,opts);

        % load the dataset
        irSet.M0(n)=b(1);
        irSet.T1(n)=b(2);
        irSet.flip_angle(n)=b(3);
        irSet.nrmse(n) = norm(res)/norm(sig);

        % save confidence intervals on the original parameters
        irSet.ci{n} = nlparci(b,res,'jacobian',jac); 

        evals = evals+1;
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
    end
end     
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);

warning('on','MATLAB:singularMatrix')

end

function [name] = setoptions(name)

if ~exist('name','var') || isempty(name)
    name = 'img';
end

end