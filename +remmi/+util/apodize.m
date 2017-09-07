function sf = apodize(s,alpha)
% sf = apodize(s,alpha) is 1D, 2D and 3D tukey apodization
%   s = data to be apodized
%   alpha = ratio of the length of the taper to the total length of the
%       window
%   sf = apodized data
%
% by Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if ~exist('alpha','var'), 
    alpha = 0.5; 
end

% window in each of the three dimensions
win1 = tukeywindow(size(s,1),alpha);
win2 = tukeywindow(size(s,2),alpha)';
win3 = reshape(tukeywindow(size(s,3),alpha),1,1,[]);

sf = bsxfun(@times,bsxfun(@times,bsxfun(@times,s,win1),win2),win3);

end

function win = tukeywindow(sz,r)

n = round(r*sz/2);

win = ones(sz,1);
win(1:n) = 0.5*(1-cos(pi*(0:n-1)/n));
win(end:-1:end-n+1) = 0.5*(1-cos(pi*(0:n-1)/n));

end