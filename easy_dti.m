clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 35;

% specify where the data will be stored
ws = remmi.workspace('easy_dti.mat');

% perform DTI analysis
ws.dti = remmi.dwi.dti(info);
