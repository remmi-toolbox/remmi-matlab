function dtiSet = dti(dset,varargin)
% dtiSet = remmi.dwi.dti(dset,mode,name) performs diffusion tensor analysis 
% on the structure: 
%
%       dset.(name) = data to process for dti 
%       dset.mask = mask for processing data
%       dset.bmat = condensed bmatrix in ms/um^2
%       dset.labels = cell array of labels to dset.(name) dimensions
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%       
%       mode = fitting routine: {'weighedlinear'}, 'linear', 'nonlinear' 
%       name = name of field in dset to fit. Default is 'img'
% 
%   Returns a data set containing dti parameter maps of ADC & FA.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

[diffFun,name] = setoptions(varargin{:});

if ~exist('dset','var')
    dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name)) ||  ...
        ~isfield(dset.(name),'mask') || isempty(dset.(name).mask)
    dset = remmi.util.thresholdmask(dset);
end

if ~isfield(dset,'bmat') || isempty(dset.bmat)
    dset = remmi.dwi.addbmatrix(dset);
end

% size of the dataset
sz = size(dset.(name)); 

% what dimension is DW encoding?
dwLabels = {'DW','NR'};
dwDim = ismember(dset.labels,dwLabels);

if ~any(dwDim)
    error('Data set does not contain multiple diffusion encodings');
end

if isfield(dset,'mask')
    mask = dset.mask;
    
    % apply the mask across all non-DW dimensions
    mask = bsxfun(@times,mask,ones(sz(~dwDim)));
else
    mask = true(sz(~dwDim));
end

% initalize data set to appropriate sizes
dtiSet.fa = zeros(sz(~dwDim));
dtiSet.adc = zeros(sz(~dwDim));
dtiSet.vec = zeros([3 3 sz(~dwDim)]);
dtiSet.eig = zeros([3 sz(~dwDim)]);

tot_evals = sum(mask(:));
evals = 0;

% make the DW dimension the first index. 
idx = 1:numel(size(dset.(name)));
data = permute(dset.(name),[idx(dwDim) idx(~dwDim)]);

if sum(dwDim) == 2
    data = reshape(data,[prod(sz(dwDim)) sz(~dwDim)]);
end

fprintf('%3.0f %% done...',0);
for n = 1:numel(mask)
    if mask(n)
        sig = abs(squeeze(data(:,n)));

        [adc,fa,vec,eig] = diffFun(sig,dset.bmat);

        dtiSet.fa(n) = fa;
        dtiSet.adc(n) = adc;
        dtiSet.vec(:,:,n) = vec;
        dtiSet.eig(:,n) = eig;
        evals = evals+1;
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
    end
end
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);

dtiSet.vec = permute(dtiSet.vec,[idx+2 1 2]);
dtiSet.eig = permute(dtiSet.eig,[idx+1 1]);

end

function [diffFun,name] = setoptions(mode,name)

if ~exist('mode','var') || isempty(mode)
    mode = 'weightedlinear';
end

% what method are we fitting for dti?
diffFun = @(x,bmat) remmi.dwi.dtiwlin(x,bmat);
if exist('mode','var')
    % nonlinear model fitting
    if strcmpi(mode,'linear')
        disp('using linear least squares')
        diffFun = @(x,bmat) remmi.dwi.dtilin(x,bmat);
    elseif strcmpi(mode,'nonlinear')
        disp('using nonlinear least squares')
        diffFun = @(x,bmat) remmi.dwi.dtinonlin(x,bmat);
    else
        disp('using weighted linear least squares')
    end
end

if ~exist('name','var') || isempty(name)
    name = 'img';
end

end