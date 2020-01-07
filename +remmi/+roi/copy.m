function rois = copy(dest_set,src_set)
% rois = remmi.roi.copy(dest_set,src_set) copys ROIs from src_set to dset_set
%
%       dest_set.(strname) = data to process
%       dest_set.mask = mask for processing data
%       dest_set.labels = cell array of labels to dset.(strname) dimensions
%
%       src_set.x{:} & str_set.yi{:} contain polygon coordinates for
%       previously drawn ROIs, provided by remmi.roi.draw()
%       src_set.roiopts contains options provided by remmi.roi.draw()
% 
%   Returns a data set containing reduced image data from the ROIs
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% by default, ROIs are drawn from dset.img
strname = src_set.roiopts.strname;
roifun = src_set.roiopts.roifun;

nROIs = src_set.roiopts.nROIs;
data = dest_set.(strname);

% what dimensions?
roidim = ismember(dest_set.labels,src_set.roiopts.labels);
if sum(roidim) ~= 2
    error('ROIs must be drawn in exactly two dimensions. Please specify labels');
end

% rearrainge to make things easier
sz =size(data); 
dims = 1:ndims(data);
data = permute(data,[dims(roidim) dims(~roidim)]);
sz = [sz(roidim) sz(~roidim)];

% set up the structure that will be returned
rois = dest_set;
rois.imgsize = [nROIs sz(~roidim)];
if numel(rois.imgsize) == 1
    rois.imgsize(2) = 1;
end
rois.(strname) = zeros(rois.imgsize);
rois.labels = {'ROI',dest_set.labels{~roidim}};
rois.mask = true(nROIs,1);

rois.xi = src_set.xi;
rois.yi = src_set.yi;

for n=1:nROIs
    bw = roipoly(dest_set.(strname),rois.xi{n},rois.yi{n});
    
    for m=1:prod(sz(~roidim))
        d = data(:,:,m);
        d = abs(d(bw));
        rois.(strname)(n,m) = roifun(d);
    end
end
