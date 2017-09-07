function dset = loadImageData(study,exps)
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
    disp('Select the study directory');
    study = uigetdir([],'Select study directory');
    if study == 0
        error('No study path given');
    end
end

if ischar(study)
    study = remmi.vendors.autoVendor(study);
end

if nargin<2
    disp('Select the experiment(s)');
    exps = study.list();
    sel = listdlg('ListString',exps.name);
    exps = exps.id(sel);
    if isempty(exps)
        error('No experiments specified in %s',spath);
    end
end

if ~iscell(exps)
    exps = num2cell(exps);
end

% load all the datasets
dset = struct();
for n=1:length(exps)
    [dset.img{n},dset.labels{n},dset.pars{n}] = study.load(num2str(exps{n}));
end

% check to see if we should combine these datasets
combine_datasets = false;

% Is there only one dataset?
if length(exps)>1 
    
    % Do the parameters have the same structure?
    sameStructure = true;
    try
        pp = [dset.pars{:}];
    catch
        % the structures here are disimilar. These data sets should not be
        % combined. 
        sameStructure = false;
    end
    
    if sameStructure
        % Does each dataset use the same sequence?
        seq = unique({pp.sequence});

        if (numel(seq) == 1)

            % Does each dataset have the same label order?
            if isequal(dset.labels{:})

                % Do all datasets have the same size?
                sz = arrayfun(@(x) size(x),dset.img,'UniformOutput',false);
                if isequal(sz{:})
                    combine_datasets = true;
                end
            end
        end
    end
else
    % There is only one experiment. Reduce the cell array.
    names = fieldnames(dset);
    for n=1:length(names)
        dset.(names{n}) = dset.(names{n}){1};
    end
end

if combine_datasets
    % Based upon similarity between the datasets, we have decided to
    % combine them into a single dataset

    % concatenate the image data
    catdim = max(length(sz{1})+1,4);
    img = cat(catdim,dset.img{:});
    labels = [dset.labels{:} 'EXP'];

    % concatenate parameters
    pars = [dset.pars{:}];
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
            try
                un = unique(par.(names{n}));
                if length(un) == 1; 
                    par.(names{n}) = un; 
                end
            catch
                % this must be a cell array of a matrix/vector. 
                if isequal(par.(names{n}){:})
                    par.(names{n}) = par.(names{n}){1}; 
                end
            end
        end
    end

    dset = struct();
    dset.img = img;
    dset.pars = par;
    dset.labels = labels;
end