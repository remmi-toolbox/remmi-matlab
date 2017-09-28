function [adc,fa,vec,eign] = dtinonlin(sig,bmat)
% function [adc,fa,vec,eign] = dtinonlin(sig,bmat) performes non-linear DTI 
% analysis
%   sig = diffusion-weighted signal
%   bmat = matrix given as [Dxx,Dyy,Dzz,Dxy,Dxz,Dyz;...]'
% 
% returns:
%   adc = apparent diffusion coefficient 
%   fa = fractional anisotropy
%   vec = 3x3 matrix of eigenvectors
%   eign = 3 eigenvalues
%
% Note: dtilin tends to be less stable than dtinonlin, but much faster.

% initial guess
x0 = [max(sig(:));ones(6,1)];
lb = [0;zeros(6,1)];
ub = [5*max(sig(:));5*ones(6,1)];
bmat = bmat(1:6,:,:);

% fit and make D matrix
D = lsqnonlin(@(x) sig-diff_sig(x,bmat),x0,lb,ub,optimset('display','off'));
D = diag(D(2:4)) + diag(D(5:6),-1) + diag(D(5:6),1) + diag(D(7),-2) + diag(D(7),2);

% eignevalue/vector decomposition
[vec,val] = eig(D);
eign = diag(val)*1000;

% calculate the apparent diffusion coefficient and fractional anisotropy
adc = mean(eign);
fa = sqrt(3/2*sum((eign-adc).^2)/sum(eign.^2));

function sig = diff_sig(x,b)
D = x(2:end);
bD = bsxfun(@times,D,b);

sig = x(1) * (exp(-permute(sum(bD(1:3,:,:))+2*sum(bD(4:6,:,:)),[2 3 1])));
