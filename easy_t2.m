clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 30;

% specify where the data will be stored
dset = remmi.dataset('easy_t2.mat');

% perform epg multiple-exponential T2 analysis
dset.epg = remmi.mse.mT2(info);
