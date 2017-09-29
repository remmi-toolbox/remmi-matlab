function exps = selectexp(study)
% exps = selectexp(study)
%   provide a basic UI to select experiments contained in study
%
%       study = char array containg the path to a valid study or a vendor
%           specific study class
%
%       exps = list of selected experiments within the study
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if ischar(study)
    study = remmi.vendors.autoVendor(study);
end

disp('Select the experiment(s)');
exps = study.list();
sel = listdlg('ListString',exps.name);
exps = exps.id(sel);