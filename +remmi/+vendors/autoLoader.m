function loader = autoLoader(spath)
% loader = autoLoader(spath)
% 
%   spath   = the path name to the study being analyzed
%   loader  = a function that will load a vendor specific experimental 
%   	image & parameter set
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

loader = [];

if ~exist(spath,'dir')
    error('Directory does not exist: %s',spath);
elseif exist(fullfile(spath,'subject'),'file') == 2;
    % this is a Bruker study
    loader = @(p)remmi.vendors.loadBruker(fullfile(spath,p));
elseif false
    % add more vendors
end

if isempty(loader)
    error('Vendor data format not recognized: %s', spath);
end