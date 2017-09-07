function hash = githash()
% hash = githash()
% 
%   returns the short hash for the current git commited version of REMMI.
%   An error is thrown if no hash is found
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

rpath = which('remmi');
rpath = fileparts(rpath);

cmd = ['git --git-dir ' fullfile(rpath,'.git')];
cmd = [cmd ' rev-parse --short HEAD'];

[stat,hash] = system(cmd);

if stat
    warning('You are not using REMMI under version control.');
    hash = '0000000';
end