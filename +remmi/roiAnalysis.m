function roiSet = roiAnalysis(dset,numROIs)
% roiSet = roiAnalysis(dset) performs ROI analysis on the dataset: 
%
%   roiAnalysis(dset,numROIs)
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox


% check labels & dimensions. only two spatial dimentions should have a
% length < 1

sz = size(dset.img);
spDim = ismember(dset.labels,{'RO','PE1','PE2'});

nSpDim = length(squeeze(sq(spDim))); % # of spatial dimensions

if nSpDim > 2
    error('Only 2 spatial dimensions can have an size > 1')
end

% now plot the images, and draw ROIs

for n=1:numROIs
    fh = figure;
    imagesc(dset.img(
    bw = 
end