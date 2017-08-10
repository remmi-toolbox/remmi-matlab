function t2set = T2Analysis(dset,metrics,fitting)
% t2set = T2Analysis(dset,metrics,fitting) performs multi-exponential T2 
%   analysis on image data in dset.
%
%   T2Analysis(dset):
%       dset.img = image data in the format (x,y,z,te)
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set including te
%
%   T2Analysis(dset,metrics)
%   metrics is a optional structure of function handles that operate on 
%   the output structure of MERA. The default metrics are the MWF, T2 and 
%   B1:
%       metrics.MWF = @(out) sum(out.Fv.*(out.Tv>0.003 & out.Tv<.017),1)./sum(out.Fv,1);
%       metrics.T2  = @(out) sum(out.Fv.*out.Tv,1)./sum(out.Fv,1);
%       metrics.B1  = @(out) out.theta;
%
%   T2Analysis(dset,metrics,fitting)
%   fitting is passed directly to MERA for multi-exponential T2/EPG 
%   analysis. By default:
%       fitting.regtyp = 'mc';
%       fitting.regadj='manual';
%       fitting.regweight=0.0005; 
%       fitting.B1fit = 'y';
%       fitting.rangetheta=[135 180];
%       fitting.numbertheta=10;
%       fitting.numberT = 100;
%       fitting.rangeT = [te(1)/2 .5];
% 
%   Returns a dataset which contains parameter maps defined in the metrics
%   structure
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

sz = size(dset.img); 

seg_sz = 256; % number of multi-echo measurements to process at one time

% what dimension is multiple echoes?
echoDim = ismember(dset.labels,'NE');

if ~any(echoDim)
    error('Data set does not contain multiple echo times');
end

% get the echo times
in.t = dset.pars.te/1000;

% define a mask if one is not given
if isfield(dset,'mask')
    mask = squeeze(dset.mask);
else
    mask = squeeze(true(prod(sz(~echoDim),1)));
end

% define the default fitting parameters if none are given
if ~exist('fitting','var')
    fitting.regtyp = 'mc';
    fitting.regadj='manual';
    fitting.regweight=0.0005; 
    fitting.B1fit = 'y';
    fitting.rangetheta=[135 180];
    fitting.numbertheta=10;
    fitting.numberT = 100;
    fitting.rangeT = [in.t(1)/2 .5];
end
analysis.graph = 'n';
analysis.interactive = 'n';

% define default metrics (MWF, T2 & B1) if none are given
if ~exist('metrics','var')
    metrics.MWF = @(out) sum(out.Fv.*(out.Tv>0.003 & out.Tv<.017),1)./sum(out.Fv,1);
    metrics.T2  = @(out) sum(out.Fv.*out.Tv,1)./sum(out.Fv,1);
    metrics.B1  = @(out) out.theta;
end

names = fieldnames(metrics);
maps = cell([length(names) sz(~echoDim)]);

% put the NE dim first
idx = 1:numel(size(dset.img));
data = permute(dset.img,[idx(echoDim) idx(~echoDim)]);

% linear index to all the vectors to process
mask_idx = find(mask);

% split the calls to MERA into segments of size seg_sz
nseg = ceil(numel(mask_idx)/seg_sz);
metlen = zeros(size(names));
for seg=1:nseg
    fprintf('Processing segment %d of %d.\n',seg,nseg);
    
    % segment the mask
    segmask = (seg_sz*(seg-1)+1):min(seg_sz*seg,numel(mask_idx));
    
    in.D = abs(data(:,mask_idx(segmask)));

    % process the data in MERA
    [out,fout] = remmi.MERA.MERA(in,fitting,analysis);

    % compute all of the metrics required
    for m=1:length(names)
        % calculate the metric
        met = metrics.(names{m})(out);
        metlen(m) = size(met,1);  % save the size for later
        
        % store the maps for later
        maps(m,mask_idx(segmask)) = num2cell(met,1);
    end
end

% set the maps into the dataset, keeping proper dimensions
t2set = struct();
for m=1:length(names)
    % index to non-empty cells
    ix=cellfun(@isempty, maps(m,:));
    
    % create matrix to hold the metric
    val = zeros([metlen(m) sz(~echoDim)]);
    val(:,~ix) = cell2mat(maps(m,:));
    
    nd = ndims(val);
    
    % rearrange
    if nd>1
        val = permute(val,[2:nd 1]);
    end
    
    % place into the return structure
    t2set.(names{m}) = val;
end

t2set.fitting = fout;
t2set.metrics = metrics;
t2set.labels = dset.labels(~echoDim);
