function dat = loaddata(fname)
% dat = loaddata(fname)
% 
%   fname = filename to a dataset to load
%   dat   = loaded dataset
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

fullname = fullfile(pwd,fname);

if exist(fullname,'file')
    dat = load(fullname);
else
    dat = struct();
end