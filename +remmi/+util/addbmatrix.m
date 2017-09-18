function dset = addbmatrix(dset)
% dset = addbmatrix(dset)
%   adds bmatrix to a datset
%
%       output: dset contains all the original contents, plus dset.bmat
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

dset.bmat = remmi.vendors.bmatBruker(dset.pars);

end