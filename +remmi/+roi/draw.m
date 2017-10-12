function rois = draw(dset,varargin)
% rois = remmi.roi.draw(dset,options) prompts to draw ROIs on data in
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
%       options.nROIs = number of ROIs or a cell array of ROI names
%
%       options.labels = label of dimensions (matching dset.(strname).labels) over
%       which to draw ROIs
%
%       options.strname = name of field in dset to fit. Default is 'img'
%
%       options.roifun = function handle on how to combine roi results. The
%       function must take a vector and return a single value. Defualt = @mean
% 
%   Returns a data set containing reduced image data from the ROIs
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

options = setoptions(varargin{:});

data = dset.(options.strname);

% which dimensions are we drawing ROIs? 
roidim = ismember(dset.labels,options.labels);
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
rois.imgsize = [options.nROIs sz(~roidim)];
if numel(rois.imgsize) == 1
    rois.imgsize(2) = 1;
end
rois.(options.strname) = zeros(rois.imgsize);
rois.labels = {'ROI',dset.labels{~roidim}};
rois.mask = true(options.nROIs,1);
rois.roiopts = options;

hf = singlefig();
for n=1:options.nROIs
    figure(hf)
    imagesc(abs(data(:,:,slidx{:})));
    colormap('gray');
    axis('image','off');
    colorbar();
    title(['Draw ROI: ' num2str(options.ROIs{n})]);
    
    [bw,xi,yi] = roipoly();
    
    rois.xi{n} = xi;
    rois.yi{n} = yi;
    
    for m=1:prod(sz(~roidim))
        d = data(:,:,m);
        d = abs(d(bw));
        rois.(options.strname)(n,m) = options.roifun(d);
    end
end

end

function hf = singlefig()
% allows ROIs to be drawn over the same figure on subsequent calls of
% remmi.roi.draw

persistent handle

if isempty(handle) || ~ishandle(handle)
	handle = figure();
end

hf = handle;

end

function opts = setoptions(opts)

if ~exist('opts','var') || ~isstruct(opts)
    opts = struct();
end

if ~isfield(opts,'nROIs') || isempty(opts.nROIs)
    opts.nROIs = 1;
end

if iscell(opts.nROIs)
    opts.ROIs = opts.nROIs;
    opts.nROIs = numel(opts.ROIs);
else
    opts.ROIs = cellfun(@num2str,num2cell(1:opts.nROIs),'UniformOutput',false);
end

% by default, draw ROIs in the RO & PE1 directions
if ~isfield(opts,'labels') || isempty(opts.labels)
    opts.labels = {'RO','PE1'};
end

% by default, ROIs are drawn from dset.img
if ~isfield(opts,'strname') || isempty(opts.strname)
    opts.strname = 'img';
end

if ~isfield(opts,'roifun') || isempty(opts.roifun)
    opts.roifun = @mean;
end 

end