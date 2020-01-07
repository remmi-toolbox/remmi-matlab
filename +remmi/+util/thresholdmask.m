function dset = thresholdmask(dset,varargin)
% dset = remmi.util.thresholdmask(dset,val,label,name)
%   adds a threshold mask to dset
%
%       dset = structure or remmi data containing:
%           dset.(name) = image data 
%           dset.labels = cell array of labels to dset.img dimensions
%       val = relative threshold value as a fraction of 
%           max(abs(dset.(name)(:))). Default is 0.1
%       label = cell array of labels to create the  mask from. Default is
%           {'RO','PE1','PE2'}
%       name = name of field in dset to threshold. Default is 'img'
%
%       output: dset contains all of the original contents, plus dset.mask
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

[val,label,name] = setoptions(varargin{:});

if ~exist('dset','var')
    dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name))
    dset = remmi.recon(dset);
end

% which dimension(s) to slice?
i = ~ismember(dset.labels,label);
img = remmi.util.slice(dset.(name),i,1);

% create a threshold mask
dset.mask = abs(img)./max(abs(img(:))) > val;

end

function [val,label,name] = setoptions(val,label,name)

if ~exist('val','var') || isempty(val)
    val = 0.1;
end
if ~exist('label','var') || isempty(label)
    label = {'RO','PE1','PE2','NS'};
end
if ~exist('name','var') || isempty(name)
    name = 'img';
end

end