clearvars

% List the study path and experiments to process
info.spath = '/path/to/study';
info.exps = 4;

% specify where the data will be stored
dset = remmi.dataset('easy_t2.mat');

%% MSE EPG
dset.imgset = remmi.recon(info);

% Set a mask based upon the first echo time image
dset.imgset = remmi.util.thresholdmask(dset.imgset);

% Process multi-TE data
dset.epg = remmi.mse.mT2(imgset);
