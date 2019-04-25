function t2Set = T2(dset,varargin)
% irSet = remmi.ir.T2(dset,name) performs T2 analysis on data in dset.
%
%       dset.(name) = data to process
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set, including te 
%       dset.labels = cell array of labels to dset.img dimensions
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%
%       name = name of field in dset to fit. Default is 'img'
% 
%   Returns a data set containing parameter maps of M0, T2 (same units
%   as dset.pars.te)
%
%   Note: this analysis assumes 180 deg refocusing pulses, and neglects
%   stimulated echo pathways (for now).
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

% what dimension is multi-echo encoding?
echoDim = ismember(dset.labels,'NE');

if ~any(echoDim)
    error('Data set does not contain multiple echo times');
end

% load in the needed parameters
te = dset.pars.te;

if numel(te)<2
    error('There are not enough echo times in this datatset for T2 analysis')
end

if numel(te) ~= sz(echoDim)
    error('The number of echo times does not match the dataset dimenions')
end

% define a mask if one is not given
if isfield(dset,'mask')
    mask = squeeze(dset.mask);
else
    mask = squeeze(true(sz(~echoDim)));
end

% initialize the mtir dataset
t2Set.M0 = zeros(size(mask));
t2Set.T2 = zeros(size(mask));
t2Set.nrmse = zeros(size(mask));
t2Set.ci = cell(size(mask));

tot_evals = sum(mask(:));
evals = 0;

% make the NE dimension the first index. 
idx = 1:numel(size(dset.(name)));
data = permute(dset.(name),[idx(echoDim) idx(~echoDim)]);

warning('off','MATLAB:singularMatrix')

t2fun = @(x) abs(x(1)*exp(-te/x(2)));

fprintf('%3.0f %% done...',0);
for n=1:numel(mask)
    if mask(n)

        sig = squeeze(abs(data(:,n)));

        % initial guess & bounds
        b0 = [max(sig), 5*te(2)-te(1);]; 
        lb = [       0,     0];
        ub = [     inf,   inf];

        % fit the data
        opts = optimset('display','off');
        [b,~,res,~,~,~,jac] = lsqnonlin(@(x) t2fun(x)-sig(:),b0,lb,ub,opts);

        % load the dataset
        t2Set.M0(n)=b(1);
        t2Set.T2(n)=b(2);
        t2Set.nrmse(n) = norm(res)/norm(sig);

        % save confidence intervals on the original parameters
        t2Set.ci{n} = nlparci(b,res,'jacobian',jac); 

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