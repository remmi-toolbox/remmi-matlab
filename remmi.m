function varargout = remmi(command)
% prototype entry point for general remmi reconstruction

if ~exist('command','var')
    command = '';
end

rname = 'remmi.mat';
dat = matfile(rname,'Writable',true);
dat.githash = remmi.util.githash();

proc = dat.process;

doproc = false;
for n=1:length(proc)
    % doproc = should this process be performed?
    doproc = doproc || strcmpi(command,proc{n}.name); % user told us to start here
    doproc = doproc || ~isprop(dat,proc{n}.name); % the field doesn't exist
    doproc = doproc || isempty(dat.(proc{n}.name)); % field is empty
    
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
        dat.(proc{n}.name) = out;
        disp(['Ending process:   ' proc{n}.name]);
    else
        % save the previous output
        proc{n}.out.data = dat.(proc{n}.name);
    end
    
end

if nargout == 1
    varargout{1} = out;
end

disp('Done!');

end % function