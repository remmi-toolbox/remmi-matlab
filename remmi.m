function imgset = remmi(command)
% prototype entry point for general remmi reconstruction

if ~exist('command','var')
    command = '';
end

rname = 'remmi.mat';
dat = remmi.util.loaddata(rname);

dat.githash = remmi.util.githash();

newstudy = strcmpi(command,'study');% user told us to select a new study
newstudy = newstudy || ~isfield(dat,'spath'); % study path doesn't exist
if newstudy
    dat.spath = uigetdir([],'Select study directory');
end

disp(['Loading the study at: ' dat.spath]);
study = remmi.vendors.autoVendor(dat.spath);

newexps = newstudy || strcmpi(command,'exp'); % user told us to select new experiments
newexps = newexps || ~isfield(dat,'exp'); % exps field doesn't exist
newexps = newexps || isempty(dat.exp); % exps field is empty
if newexps 
    explist = study.list();
    sel = listdlg('ListString',explist.name);
    dat.exp = explist.id(sel);
    
    % save the dataset info
    remmi.util.savedata(rname,dat);
end

iname = 'imgset.mat';
imgset = remmi.util.loaddata(iname);

recon = newexps || strcmpi(command,'recon'); % user told us to reconstruct
recon = recon ||  ~isfield(imgset,'img'); % images don't exist
recon = recon || isempty(imgset.img); % images are empty
if recon
    disp(['Loading experiments: ' strjoin(dat.exp,',')]);
    imgset = remmi.loadImageData(study,dat.exp);
    
    % save the images
    remmi.util.savedata(iname,imgset);
end

end % function