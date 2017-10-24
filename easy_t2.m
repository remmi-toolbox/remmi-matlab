clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 30;

% specify where the data will be stored
dset = remmi.dataset('easy_t2.mat');

% load default options
options = remmi.mse.mT2options();

% set T2 bounds on the MWF
lb = 0.005; ub = 0.20;
options.MWF = @(out)remmi.mse.calcT2frac(out,lb,ub); 

% perform epg multiple-exponential T2 analysis
dset.epg = remmi.mse.mT2(info,options);
