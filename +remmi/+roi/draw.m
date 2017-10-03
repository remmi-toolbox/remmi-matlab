function rois = draw(dset,nROIs,labels,strname)
% rois = remmi.roi.draw(dset,nROIs,labels,strname) prompts to draw ROIs on data in
% dset
%
%       dset.(strname) = data to process
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set including ti & td. 
%       dset.labels = cell array of labels to dset.img dimensions
%
%       if dset or dset.(strname) is not given, default reconstruction and
%       thresholding methods are called
%
%       nROIs = number of ROIs or a cell array of ROI names
%
%       labels = label of dimensions (matching dset.(strname).labels) over
%       which to draw ROIs
%
%       strname = name of field in dset to fit. Default is 'img'
% 
%   Returns a data set containing reduced image data from the ROIs
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% default number of ROIs
if ~exist('nROIs','var') || isempty(nROIs)
    nROIs = 1;
end

if iscell(nROIs)
    ROIs = nROIs;
    nROIs = numel(ROIs);
else
    ROIs = cellfun(@num2str,num2cell(1:nROIs),'UniformOutput',false);
end

% by default, draw ROIs in the RO & PE1 directions
if ~exist('labels','var') || isempty(labels)
    labels = {'RO','PE1'};
end

% by default, ROIs are drawn from dset.img
if ~exist('name','var') || isempty(strname)
    strname = 'img';
end

data = dset.(strname);

% which dimensions are we drawing ROIs? 
roidim = ismember(dset.labels,labels);
sz =size(data); 

% check that we are drawing ROIs for exactly 2 dimensions
if sum( roidim & (sz>1) ) ~=2
    error('ROIs must be drawn in exactly two dimensions. Please specify labels')
end

% rearrainge to make things easier
dims = 1:ndims(data);
data = permute(data,[dims(roidim) dims(~roidim)]);
sz = [sz(roidim) sz(~roidim)];

% what indexes are we drawing over? For now, just the slice with the
% maximum signal. Is it possible to be smarter about this? Certainly...
[~,idx] = max(abs(data(:)));
slidx = cell(1,length(sz));
[slidx{:}] = ind2sub(sz,idx);
slidx = slidx(~roidim);

% set up the structure that will be returned
rois = dset;
rois.imgsize = [nROIs sz(~roidim)];
rois.(strname) = zeros(rois.imgsize);
rois.labels = {'ROI',dset.labels{~roidim}};
rois.mask = true(nROIs,1);

hf = singlefig();
for n=1:nROIs
    figure(hf)
    imagesc(abs(data(:,:,slidx{:})));
    colormap('gray');
    axis('image','off');
    colorbar();
    title(['Draw ROI: ' num2str(ROIs{n})]);
    
    [bw,xi,yi] = roipoly();
    
    rois.xi{n} = xi;
    rois.yi{n} = yi;
    
    rois.(strname)(n,:) = reshape(squeeze(sum(sum(bsxfun(@times,bw,data),1),2)),[],1);
end

function hf = singlefig()
% allows ROIs to be drawn over the same figure on subsequent calls of
% remmi.roi.draw

persistent handle

if isempty(handle) || ~ishandle(handle)
	handle = figure();
end

hf = handle;