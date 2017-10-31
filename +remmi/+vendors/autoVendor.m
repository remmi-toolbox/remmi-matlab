function loader = autoVendor(spath)
% loader = autoVendor(spath)
% 
%   spath   = the path name to the study being analyzed
%   loader  = a vendor-specific class to load image & parameter set
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

loader = [];

if ~exist(spath,'dir')
    error('Directory does not exist: %s',spath);
elseif remmi.vendors.BrukerPV.isValid(spath)
    loader = remmi.vendors.BrukerPV(spath);
elseif remmi.vendors.Varian.isValid(spath)
    loader = remmi.vendors.Varian(spath);
elseif false
    % todo: add new vendors
end

if isempty(loader)
    error('Vendor data format not recognized: %s', spath);
end
