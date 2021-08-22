function adcSet = adc(dset,varargin)
% adcSet = remmi.dwi.adc(dset,name) calculates ADC maps from data
% in the dset structure:
%
%       dset.(name) = data to process for dti
%       dset.mask = mask for processing data
%       dset.bmat = condensed bmatrix
%       dset.labels = cell array of labels to dset.(name) dimensions
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%
%       name = name of field in dset to fit. Default is 'img'
%
%   Returns a data set containing a mean B0 image and ADC parameter maps
%   for each non B0 image.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

[name] = setoptions(varargin{:});

if ~exist('dset','var')
  dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name)) ||  ...
    ~isfield(dset,'mask') || isempty(dset.mask)
  disp('Using default mask') % alert user that default mask in use  
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

% average the B0 images
isB0 = false(sz(ismember(dset.labels,'DW')),1);
nB0 = dset.pars.methpars.PVM_DwAoImages;
if isfield(dset.pars.methpars,'REMMI_DwAoImagesEnd')
  nB0end = dset.pars.methpars.REMMI_DwAoImagesEnd;
  isB0(1:nB0-nB0end) = true;
  isB0(end-nB0end+1:end) = true;
else
  isB0(1:nB0) = true;
end

if ~any(isB0)
  % DwAo images = 0, look for b-value=0
  isB0 = dset.pars.methpars.PVM_DwBvalEach==0;
  
  if ~any(isB0)
    error('no b=0 images are given');
  end
end

% initalize data set to appropriate sizes
adcSet.adc = zeros([sz(~dwDim) sum(~isB0)]);

% calculate the average "b0" image
dwidx = find(ismember(dset.labels,'DW'));
b0idx = cell(size(sz));
b0idx(:) = {':'};
b0idx{dwidx} = isB0;
adcSet.b0 = mean(dset.(name)(b0idx{:}),dwidx).*mask;
b0_bval = sum(dset.bmat(1:3,isB0),1);

notB0 = find(~isB0);
for n=1:length(notB0)
  idx = cell(size(sz));
  idx(:) = {':'};
  idx{dwidx} = notB0(n);
  idx_out = idx;
  idx_out{dwidx} = n;
  d_bval = sum(dset.bmat(1:3,notB0(n))) - b0_bval;
  adcSet.adc(idx_out{:}) = -log(abs(dset.(name)(idx{:})./adcSet.b0))/d_bval.*mask*1000;
end

end

function [name] = setoptions(name)

if ~exist('name','var') || isempty(name)
  name = 'img';
end

end