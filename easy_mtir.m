clearvars

% List the study path and experiments to process
info.spath = './data/mt';
info.exps = 29;

% specify where the data will be stored
dset = remmi.dataset('easy_mtir.mat');

%% MTIR analysis

% reconstruct the images
dset.images = remmi.recon(info);

% Set a mask
dset.images = remmi.util.thresholdmask(dset.images);

% process MTIR
dset.mtir = remmi.ir.qmt(dset.images);
