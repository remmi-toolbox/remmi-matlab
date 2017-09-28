clearvars

% List the study path and experiments to process
info.spath = './data/mt';
info.exps = 29;

% specify where the data will be stored
dset = remmi.dataset('easy_dti.mat');

%% dti processing
dset.images = remmi.recon(info);

% and b-matrix
dset.images.bmat = remmi.dwi.addbmatrix(dset.images);

% Set a mask 
dset.images = remmi.util.thresholdmask(dset);

% perform DTI analysis
dset.dti = remmi.dwi.dti(dset.images);
