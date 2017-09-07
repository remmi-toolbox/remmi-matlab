function savedata(fname,dat)
% dat = savedata(fname)
% 
%   fname = filename to save the dataset 
%   dat  = dataset to save
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

fullname = fullfile(pwd,fname);
save(fullname,'-struct','dat');
