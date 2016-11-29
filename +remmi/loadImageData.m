function dset = loadImageData(spath,exps)
% dset = loadImageData(spath,exps) loads raw data from recognized 
%   pre-clinical MRI data formats, and returns reconstructed images and
%   parameters.
%   
% optional inputs:
%   spath = string path to a study stored in a recognized vender format
%   exps = list of experiments to reconstruct within spath 
%
% output:
%   dset = a structure (or array of structures) containing:
%       dset.img  = reconstructed images
%       dset.pars = list of experimental parameters used during image
%           acquisition
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if nargin<1
    spath = uigetdir([],'Select study');
    if spath == 0
        error('No study path given');
    end
end

% what vendor is the study?
study = remmi.vendors.autoVendor(spath);

if nargin<2
    exps = study.list();
    sel = listdlg('ListString',exps);
    exps = exps(sel);
    if isempty(exps)
        error('No experiments specified in %s',spath);
    end
end

if ~iscell(exps)
    exps = num2cell(exps);
end

% load all the datasets
for n=1:length(exps)
    [dset(n).img,dset(n).pars] = study.load(num2str(exps{n}));
end

% check to see if we should combine these datasets
combine_datasets = false;

% Is there only one dataset?
if length(exps)>1
    pp = [dset.pars];
    seq = unique({pp.sequence});
    
    % Does each dataset use the same sequence?
    if (numel(seq) == 1)
        nte = unique([pp.nte]);
        
        % Does each dataset have the same number of echo times?
        if (numel(nte) == 1)
            sz = arrayfun(@(x) size(x.img),dset,'UniformOutput',false);
            
            % Do all datasets have the same size?
            if isequal(sz{:})
                combine_datasets = true;
            end
        end
    end
end

if combine_datasets
    % Based upon similarity between the datasets, we have decided to
    % combine them into a single dataset

    % concatenate the image data
    catdim = max(length(sz{1})+1,4);
    img = cat(catdim,dset.img);

    % concatenate parameters
    pars = [dset.pars];
    names = fieldnames(pars(1));
    for n=1:length(names)
        if length(pars(1).(names{n})) > 1
            sz = size(pars(1).(names{n}));
            par.(names{n}) = cat(length(sz)+1,{pars.(names{n})});
        else
            % array concatenation
            par.(names{n}) = [pars.(names{n})];
        end

        if ~isstruct(par.(names{n})(1))
            % if all of the parameter values are identical, replace them
            % with a single value.
            un = unique(par.(names{n}));
            if length(un) == 1; 
                par.(names{n}) = un; 
            end
        end
    end

    dset = struct();
    dset.img = img;
    dset.pars = par;
end