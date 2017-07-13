function dtiSet = dtiAnalysis(dset,mode)
% dtiSet = dtiAnalysis(dset) performs DTI analysis on the dataset: 
%
%   dtiAnalysis(dset)
%       dset.img = image data in the format (x,y,z,:,diff) (constant td)
%       dset.mask = mask for processing data (optional, but speeds up
%           computation time)
%       dset.bmat = condensed bmatrix in ms/µm^2
%       mode = {'linear'}, 'nonlinear'
% 
%   Returns a data set containing dti parameter maps of ADC & FA.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% size of the dataset
sz = size(dset.img); 

% what dimension is DW encoding?
dwDim = ismember(dset.labels,'DW');

if ~any(dwDim)
    error('Data set does not contain multiple diffusion encodings');
end

if isfield(dset,'mask')
    mask = dset.mask;
else
    mask = true(prod(sz(~dwDim),1));
end

diffFun = @(x) remmi.util.dtilin(x,dset.bmat);
if exist('mode','var')
    % nonlinear model fitting
    if strcmpi(mode,'nonlinear')
        diffFun = @(x) remmi.util.dtinonlin(x,dset.bmat);
    end
end

% initalize data set to appropriate sizes
dtiSet.fa = zeros(sz(~dwDim));
dtiSet.adc = zeros(sz(~dwDim));
dtiSet.vec = zeros([3 3 sz(~dwDim)]);
dtiSet.eig = zeros([3 sz(~dwDim)]);

tot_evals = sum(mask(:))*sz(4);
evals = 0;

% make the DW dimension the first index. 
idx = 1:numel(size(dset.img));
data = permute(dset.img,[idx(dwDim) idx(~dwDim)]);

fprintf('%3.0f %% done...',0);
for n = 1:numel(mask)
    if mask(n)
        sig = abs(squeeze(data(:,n)));

        [adc,fa,vec,eig] = diffFun(sig);

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
