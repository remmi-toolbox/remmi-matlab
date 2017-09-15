function varargout = remmi(proc,data,command)
% WIP entry point for remmi reconstruction/analysis in batch
%
% out = remmi(procfile,command)
%
%   inputs:
%   proc = a cell array of structures containing:
%       proc.name = the string name of the process
%       proc.in = a cell array of inputs to process.function. These inputs
%           can (should?) be objects of type remmi.dataset
%       proc.function = anonymous function  
%       proc.out = if applicable, a single remmi.dataset output returned 
%           from process.function
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

% must have a list of process. 
if ~exist('proc','var')
    error('no proc given');
end

% no default data
if ~exist('data','var')
    data{1}.fname = 'remmi.mat';
else
    % default .mat file names
    for n=1:length(data)
        if ~isfield(data{n},'fname')
            data{n}.fname = ['remmi' num2str(n) '.mat'];
        end
    end
end

% no default command
if ~exist('command','var')
    command = '';
end

for n=1:length(data)
    datfile = remmi.dataset.matfile(data{n}.fname);
    
    % pre-load fields from this initial dataset
    f = fields(data{n});
    for m=1:length(f)
        datfile.(f{m}) = data{n}.(f{m});
    end
    
    if nargout == length(data)
        varargout{n} = remmi_proc(proc,datfile,command);
    else
        remmi_proc(proc,datfile,command);
    end
    
end

end

function varargout = remmi_proc(proc,datfile,command)

% parse the procfile
if ischar(datfile)
    
elseif isa(datfile,'matlab.io.MatFile')
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