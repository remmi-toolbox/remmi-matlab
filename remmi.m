function varargout = remmi(info,command)
% WIP entry point for remmi reconstruction/analysis in batch
%
% out = remmi(info)
%
%   inputs:
%   info
%       info.proc = a cell array of structures containing:
%           proc.name = the string name of the process
%           proc.in = a cell array of inputs to process.function. These inputs
%               can (should?) be objects of type remmi.dataset
%           proc.function = anonymous function  
%           proc.out = if applicable, a single remmi.dataset output returned 
%               from process.function
%       info.fname = .mat filename to store the data
%
%   data = a structure of data to pre-configure any proc
%       
%   command = a string listing the name (i.e. proc.name) of the 
%   process to begin processing. 
%
%   outputs:
%   out = a data structure containing the data returned from the last
%       process. If procfile is a cell array, out must have the same number
%       of elements as datfile. 
%
%   See epg_proc.m, qmt_proc.m, and dti_proc.m for examples of how to
%   generate procfiles. 
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% must have a some info to start with. 
if ~exist('info','var')
    error('no info given');
end

% make sure this is a cell array
if ~iscell(info)
    info = {info};
end

% no default command
if ~exist('command','var')
    command = '';
end

% loop through processing steps
for n=1:length(info)
    % must have a list of processes. 
    if ~isfield(info{n},'proc')
        warning('no proc given, using basic reconstruction');
        info{n}.proc = remmi.proc.recon();
    end

    % no default data
    if ~isfield(info{n},'fname')
        info{1}.fname = ['remmi.mat' num2str(n) 'mat'];
    end

    datfile = remmi.dataset.matfile(info{n}.fname);
    
    % pre-load fields from this initial dataset
    f = fields(info{n});
    for m=1:length(f)
        if ~isempty(info{n}.(f{m}))
            datfile.(f{m}) = info{n}.(f{m});
        end
    end
    
    if nargout == length(info)
        varargout{n} = remmi_proc(info{n}.proc,datfile,command);
    else
        remmi_proc(info{n}.proc,datfile,command);
    end
    
end

end

function varargout = remmi_proc(proc,datfile,command)

% parse the procfile
if isa(datfile,'matlab.io.MatFile')
    dat = datfile;
    datfile = datfile.Properties.Source;
else
    error('"procfile" not recognized');
end

% save information about this call & version of remmi
info.remmi_proc = proc;
info.remmi_githash = remmi.util.githash();
info.remmi_version = remmi.version();
dat.info = info;

doproc = false;
for n=1:length(proc)
    % doproc = should this process be performed?
    doproc = doproc || strcmpi(command,proc{n}.name); % user told us to start here
    doproc = doproc || ~isprop(dat,proc{n}.out.name); % the field doesn't exist
    doproc = doproc || isempty(dat.(proc{n}.out.name)); % field is empty
    
    if doproc
        disp(['Begining process: ' proc{n}.name]);
        
        % set up input variables
        in = cell(proc{n}.in);
        for m=1:numel(proc{n}.in)
            in{m} = proc{n}.in{m}.data;
        end
        
        % do your business
        out = proc{n}.function(in);
        
        % save the output
        proc{n}.out.data = out;
        disp(['Ending process:   ' proc{n}.name]);
    end
end

% if an output is requested, return the last result
if nargout == 1
    varargout{1} = proc{end}.out.data;
end

disp('Done!');

end % function