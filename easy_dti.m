clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 35;

% specify where the data will be stored
dset = remmi.dataset('easy_dti.mat');

% perform DTI analysis
dset.dti = remmi.dwi.dti(info);
