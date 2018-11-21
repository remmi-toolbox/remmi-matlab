function [sig,img] = pocs(zf_sig,niter)
% [sig,img] = pocs(zf_sig,niter) fills in zeros from 2d or 3d partial 
% aquired Fourier data using a low pass filter of the image phase 
%
% zf_sig = partially acquried Fourier encoded signals. Unacquired signals 
%   are = 0. The method assumes the first three dimensions are Fourier  
%   encoded, and all other dimensions contain the same missing signals.
% niter = number of iterations. Default is 50
%
% sig = k-space signal, with 0s filled in via the POCS algorithm
% img = images reconstructed from these signals
%
% by Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if ~any(zf_sig==0)
    % this is not partial Fourier data, no need to move forward
    sig = zf_sig;
    return
end

if ~exist('niter','var')
    niter = 50; % default # of iterations
end

% If more than one set of image data is present, evaluate missing signals 
% from only the first image
ksp = zf_sig(:,:,:,1);

% where is the center of k-space?
[~,i] = max(ksp(:));
idx = cell(ndims(ksp),1);
[idx{:}] = ind2sub(size(ksp),i);

% calculate the filter for the low-pass image based upon the distance from 
% the center of k-space to the un-acquired signals
dist = bwdist(ksp==0);
wnd = floor(dist(idx{:}));
fn = wnd - abs(dist-wnd);
fn(fn<0) = 0;
lp_filt = sin(fn/wnd*pi/2); % sin filter

% calculate the filter used to update k-space data for each iteration
dist(dist>2*wnd) = 2*wnd;
it_filt = dist/2/wnd;%sin(dist/wnd*pi/2); % ramp filter

% zero-filled image 
zf_img = ift(zf_sig);

% low pass image
lp_sig = bsxfun(@times,zf_sig,lp_filt);
lp_img = ift(lp_sig);

% zero filed image as the inital guess
img = zf_img; 

for n=1:niter
    % estimate the image as the magnitude of the high-pass homodyne
    % recon times the phase of the low-pass homodyne recon
    i2 = abs(img).*exp(1i*angle(lp_img));
    i2fft = ft(i2);
    
    % combine estimated + acquired signals
    sig = bsxfun(@times,i2fft,1-it_filt) + bsxfun(@times,zf_sig,it_filt);
    img = ift(sig);
end

end

function x = ift(x)
% inverse fourier transform
x = fftshift(fftshift(fftshift(x,1),2),3);
x = ifft(ifft2(x),[],3);
x = fftshift(fftshift(fftshift(x,1),2),3);
end

function x = ft(x)
% fourier transform
x = fftshift(fftshift(fftshift(x,1),2),3);
x = fft(fft2(x),[],3);
x = fftshift(fftshift(fftshift(x,1),2),3);
end