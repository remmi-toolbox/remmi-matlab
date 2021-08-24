function [denoised,S2,P] = mp_denoise(dset,win_size,name)
% function [denoised,S2,P] = mp_denoise(image,win_size,name)
%
% INPUT: 
%       dset.(name) = images to be denoised. The first dimensions must
%         discriminate between pixels, while the last dimension corresponds
%         to encoding variation (diffusion, echo time, inverion-time, or other). 
%         Thus, could be structured as [X,Y,Z,N] or [X,Y,N].  
%       dset.mask = mask for processing data

%       win_size = the size of the sliding window for PCA analysis for each 
%         image dimension (e.g., [5 5 5] for a 3D image. 
%         If not specified, the default is Nw*ones(1,Nd), where
%         Nd = ndims(img)-1; dimension of the image, and 
%         Nw = ceil(size(dset.images.img,Nd+1).^(1/Nd));
%       name = name of field in dset to fit. Default is 'img'
%
% OUTPUT: denoisedImage - contains denoised image with same structure as
% input.
%
% S2 - contains estimate of variance in each pixel.
%
% P - specifies the found number of principal components.
%
% CREDIT:
% Denoising implementation by Jonas Olesen and Sune Jespersen for diffusion
% MRI data based on the algorithm presented by Veraart et al. (2016) 142, p
% 394-406 https://doi.org/10.1016/j.neuroimage.2016.08.016.
%
% MDD minor modifications
% - to remove mean across voxels (compute principal components of
% the covariance not correlation matrix) 
% - to use MATLAB's svd--slightly slower but more accurate
% - to conform to remmi conventions 


%% check and set variables

if ~exist('name','var') || isempty(name)
    name = 'img';
end

img = dset.(name);

Nd = ndims(img)-1; % dimension of the image,  
% If images is 2D, extend to 3D with size of 3rd dim = 1
if Nd==2
  img = permute(img,[1,2,4,3]);
end

image_size = size(img,1:3);
M = size(img,4); % length of contrast encoding dimension
Nw = ceil(M.^(1/Nd)); % default size of moving window along each dim

if ~exist('win_size','var') || isempty(win_size)
    win_size = Nw*ones(1,Nd);
else % check win_size
  assert((length(win_size)==Nd),...
    'length of win_size must match dim of images')
  assert(all(win_size>0),'window values must be strictly positive')
  assert(all(win_size<=image_size),...
  'window values exceed image dimensions')   
end

if length(win_size)==2
    win_size(3) = 1;
end

N = prod(win_size);

if isfield(dset,'mask') 
  mask = dset.mask;
else
  disp('No mask')
  mask = [];
end



%% denoise image
denoised = zeros([image_size,M]);
P = zeros(image_size);
S2 = zeros(image_size);
counter = zeros(image_size);
m = image_size(1)-win_size(1)+1;
n = image_size(2)-win_size(2)+1;
o = image_size(3)-win_size(3)+1;

for index = 1:m*n*o
  k = floor((index-1)/m/n)+1;
  j = floor((index-1-(k-1)*m*n)/m)+1;
  i = index-(k-1)*m*n-(j-1)*m;
  rows = i:i-1+win_size(1);
  cols = j:j-1+win_size(2);
  slis = k:k-1+win_size(3);
  % Check mask
  maskCheck = reshape(mask(rows,cols,slis),[N 1])';
  if all(~maskCheck), continue, end
  
  % Create X data matrix
  X = reshape(img(rows,cols,slis,:),[N M])';
  
  % Remove voxels not contained in mask
  X(:,~maskCheck) = [];
  if size(X,2)==1, continue, end % skip if only one voxel of window in mask
  % Perform denoising
  newX=zeros(M,N); sigma2=zeros(1,N); p=zeros(1,N);
  [newX(:,maskCheck),sigma2(maskCheck),p(maskCheck)] = denoiseMatrix(X);
  
  % Assign newX to correct indices in denoisedImage
  denoised(rows,cols,slis,:) = denoised(rows,cols,slis,:) ...
    + reshape(newX',[win_size M]);
  P(rows,cols,slis) = P(rows,cols,slis) + reshape(p,win_size);
  S2(rows,cols,slis) = S2(rows,cols,slis) + reshape(sigma2,win_size);
  counter(rows,cols,slis) = counter(rows,cols,slis)+1;
end
skipCheck = mask & counter==0;
counter(counter==0) = 1;
denoised = bsxfun(@rdivide,denoised,counter);
P = bsxfun(@rdivide,P,counter);
S2 = bsxfun(@rdivide,S2,counter);


%% adjust output to match input dimensions
% Assign original data to denoisedImage outside of mask and at skipped voxels
original = bsxfun(@times,img,~mask);
denoised = denoised + original;
original = bsxfun(@times,img,skipCheck);
denoised = denoised + original;

% Shape denoisedImage as orginal image
if Nd==2
  denoised = reshape(denoised,[image_size(1:2),M]);
  S2 = reshape(S2,image_size(1:2));
  P = reshape(P,image_size(1:2));
end

end

function [newX,sigma2,p] = denoiseMatrix(X)
% helper function to denoise.m
% Takes as input matrix X with dimension MxN with N corresponding to the
% number of pixels and M to the number of data points. The output consists
% of "newX" containing a denoised version of X, "sigma2" an approximation
% to the data variation, "p" the number of signal carrying components.

[M,N] = size(X);
minMN = min([M N]);
Xm = mean(X,2); % MDD added Jan 2018; mean added back to signal below;
X = X-Xm;
% [U,S,V] = svdecon(X); MDD replaced with MATLAB svd vvv 3Nov2017
[U,S,V] = svd(X,'econ');

lambda = diag(S).^2/N;

p = 0;
pTest = false;
scaling = (M-(0:minMN))/N;
scaling(scaling<1) = 1;
while ~pTest
  sigma2 = (lambda(p+1)-lambda(minMN))/(4*sqrt((M-p)/N));
  pTest = sum(lambda(p+1:minMN))/scaling(p+1) >= (minMN-p)*sigma2;
  if ~pTest, p = p+1; end
end
sigma2 = sum(lambda(p+1:minMN))/(minMN-p)/scaling(p+1);

newX = U(:,1:p)*S(1:p,1:p)*V(:,1:p)'+Xm;

end


