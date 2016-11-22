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
win1 = tukeywin(size(s,1),alpha);
win2 = tukeywin(size(s,2),alpha)';
win3 = reshape(tukeywin(size(s,3),alpha),1,1,[]);

sf = bsxfun(@times,bsxfun(@times,bsxfun(@times,s,win1),win2),win3);