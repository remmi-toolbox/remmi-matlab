function varargout = remmi(procfile,command)
% WIP entry point for remmi reconstruction/analysis in batch
%
% out = remmi(procfile,command)
%
%   inputs:
%   procfile = string path to a .mat file containing a variable named 
%       'process':
%           process = a cell array of structures containing:
%           process.name = the string name of the process
%           process.in = a cell array of inputs to process.function. These
%               inputs must be objects of type remmi.dataset
%           process.function = anonymous function  
%           process.out = a single remmi.dataset output returned from
%               process.function
%
%   For larger scale batch processing, procfile can also be a cell array
%   of path names
%       
%   command = a string listing the name (i.e. process.name) of the 
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

% must have a procfile. 
if ~exist('procfile','var')
    error('no procfile given');
end

% converty to a cell array if not already one
if ~iscell(procfile)
    procfile = {procfile};
end

% no default command
if ~exist('command','var')
    command = '';
end

if nargout
    % if an output is wanted, return one
    varargout = cell(size(procfile));
    for n=1:numel(procfile)
        varargout{n} = remmi_proc(procfile{n},command);
    end
else
    % no output was requested. 
    for n=1:numel(procfile)
        remmi_proc(procfile{n},command);
    end
end

end

function varargout = remmi_proc(procfile,command)

% parse the procfile
if ischar(procfile)
    dat = remmi.dataset.matfile(procfile,false);
elseif isa(procfile,'matlab.io.MatFile')
    dat = procfile;
    procfile = procfile.Properties.Source;
else
    error('"procfile" not recognized');
end

% save information about this call & version of remmi
info.input_matfile = procfile;
info.remmi_githash = remmi.util.githash();
info.remmi_version = remmi.version();
dat.info = info;

try
    proc = dat.process;
catch
    error('procfile does not seem to be valid')
end

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