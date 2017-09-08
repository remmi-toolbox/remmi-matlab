function dset = thresholdmask(dset,val,label)
% dset = thresholdmask(dset,val,label)
%   adds a threshold mask to dset
%
%       dset = structure containing:
%           dset.img = image data 
%           dset.labels = cell array of labels to dset.img dimensions
%       val = relative threshold value as a fraction of 
%           max(abs(dset.img(:))). Default is 0.1
%       label = cell array of labels to mask through. Default is ...
%           {'IR','NE','DW','NR'}
%
%       output: dset contains all of the original contents, plus dset.mask
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if nargin < 2
    val = 0.1;
end
if nargin < 3
    label = {'IR','NE','DW','NR'};
end

% which dimension(s) to slice?
i = ismember(dset.labels,label);
img = remmi.util.slice(dset.img,i,1);

% create a threshold mask
dset.mask = abs(img)./max(abs(img(:))) > val;