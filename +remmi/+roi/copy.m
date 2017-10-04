function rois = copy(dest_set,src_set,strname)
% rois = remmi.roi.copy(dest_set,src_set) copys ROIs from src_set to dset_set
%
%       dest_set.(strname) = data to process
%       dest_set.mask = mask for processing data
%       dest_set.labels = cell array of labels to dset.(strname) dimensions
%
%       src_set.x{:} & str_set.yi{:} contain polygon coordinates for
%       previously drawn ROIs, like that in remmi.roi.draw()
%
%       strname = name of field in dset to fit. Default is 'img'
% 
%   Returns a data set containing reduced image data from the ROIs
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% by default, ROIs are drawn from dset.img
if ~exist('name','var') || isempty(strname)
    strname = 'img';
end

nROIs = numel(src_set.xi);
data = dest_set.(strname);

% what dimensions?
labels = dest_set.labels(~ismember(dest_set.labels,src_set.labels));
roidim = ismember(dest_set.labels,labels);
roidim = (roidim & cumsum(roidim)<=2); %only use the first two dimensions

% rearrainge to make things easier
sz =size(data); 
dims = 1:ndims(data);
data = permute(data,[dims(roidim) dims(~roidim)]);
sz = [sz(roidim) sz(~roidim)];

% set up the structure that will be returned
rois = dest_set;
rois.imgsize = [nROIs sz(~roidim)];
rois.(strname) = zeros(rois.imgsize);
rois.labels = {'ROI',dest_set.labels{~roidim}};
rois.mask = true(nROIs,1);

rois.xi = src_set.xi;
rois.yi = src_set.yi;

for n=1:nROIs
    bw = roipoly(dest_set.(strname),rois.xi{n},rois.yi{n});
    
    rois.(strname)(n,:) = reshape(squeeze(sum(sum(bsxfun(@times,bw,data),1),2)),[],1);
end
