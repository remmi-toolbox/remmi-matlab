function [fpath,pre,post,fext] = parsename(fname)
% [fpath,pre,post,fext] = parsename(fname)
% 
%   similar to fileparts, but also splits up the remmi batch process file
%   name into its base (fpre) time-stamped (fpost) components
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

[fpath,fname,fext] = fileparts(fname);

parts = remmi.util.strsplit(fname,'_');

if length(parts)>2
    error('filename not recognized');
end

pre = fullfile(fpath,parts{1});

if length(parts) > 1
    post = parts{2};
else
    post = '';
end
