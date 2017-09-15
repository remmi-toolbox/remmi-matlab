function splitstr = strsplit(str,delim)
% splitstr = strsplit(str,delim)
% 
%   Since Matlab's strsplit was introduced in R2013a, this version is
%   included to improve backwards compatbility for REMMI.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

splitstr = regexp(str,regexptranslate('escape',delim),'split');

end