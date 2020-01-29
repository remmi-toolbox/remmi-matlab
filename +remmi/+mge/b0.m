function b0set = b0(dset,name)
% b0set = remmi.b0(dset,name) calculates B0 from complex multi-gradient 
% echo images.
%
%       dset.(name) = data to process for dti 
%       dset.mask = mask for processing data
%       dset.bmat = condensed bmatrix in ms/um^2
%       dset.labels = cell array of labels to dset.(name) dimensions
%       dset.pars.te = list of echo times (in seconds) used to process. 
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%       
%       name = name of field in dset to fit. Default is 'img'
% 
%   Returns a data set containing B0 map (in units of Hz). B0 is calculated
%   via a weighted average of phase differences calculated from
%   multi-gradient echo images. The processing assumes alternating 
%   positive and negative readout directions.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if ~exist('name','var')
    name = 'img';
end

if ~exist('dset','var')
    dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name)) ||  ...
        ~isfield(dset.(name),'mask') || isempty(dset.(name).mask)
    dset = remmi.util.thresholdmask(dset);
end

% size of the dataset
sz = size(dset.(name)); 

% what dimension is DW encoding?
echoLabels = {'NE'};
echoDim = ismember(dset.labels,echoLabels);

if ~any(echoDim)
    error('Data set does not contain multiple echo images');
end

msz = sz;
msz(echoDim) = 1;
if isfield(dset,'mask')
    mask = dset.mask;
    
    % apply the mask across all non-NE dimensions
    mask = bsxfun(@times,mask,ones(msz));
else
    mask = true(msz);
end

freq_sum = 0;
mag_sum = 0;
for n=1:numel(dset.pars.te)-2
    idx = cell(length(sz),1);
    idx(~echoDim) = {':'};
    idx(echoDim) = {n};
    idx2 = idx;
    idx2(echoDim) = {n+2};
    delta_te = dset.pars.te(n+2)-dset.pars.te(n);
    
    % calculate the phase difference between subsequent echoes with the
    % same readout direction. As given in Bernstien Eq 13.112
    ph = angle(dset.(name)(idx2{:})./dset.(name)(idx{:}));
    freq_off = ph/delta_te/2/pi;
    
    % We need to average the phase change across the multiple echo times
    % acquired. Because image intensity can vary down the echo train (due
    % to T2* or B0 inhomogeneity), we use a weighted average. What weight
    % should we use?
    %
    % The phase difference is calculated between two image signals. The
    % error in the esimated phase depends upon the signal magnitude in both
    % images. High intensities in both signals means high accuracy in the
    % estimate of the phase. If one or both of those signals has a low
    % intensity, the estimate of the phase will be more susceptible to
    % noise.
    %
    % We weight the average using the harmonic mean of the two images used
    % to calculate the phase difference, which will be low when one/both
    % signals contain low signal levels.
    mag = 1./(1./abs(dset.(name)(idx{:})) + 1./abs(dset.(name)(idx2{:})));
    
    % sum the weight, and the frequency times the weight.
    freq_sum = freq_sum + mag.*freq_off;
    mag_sum = mag_sum + mag;
end

% calculate the weighted average
b0set.b0 = freq_sum./mag_sum.*mask;
