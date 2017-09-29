clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 30;

% specify where the data will be stored
dset = remmi.dataset('full_t2.mat',info);

% reconstruct the data
dset.images = remmi.recon(info);

% Set a mask based upon the first echo time image
dset.images = remmi.util.thresholdmask(dset.images);

% load the default metrics for mT2 analysis
metrics = remmi.mse.mT2options();

% add a spectrum to the output
metrics.S = @(out) out.S;

% Process multi-TE data
dset.epg = remmi.mse.mT2(dset.images,metrics);

% draw a few ROIS
dset.ROIs = remmi.roi.draw(dset.images,3);

% Process ROI data
dset.ROI_epg = remmi.mse.mT2(dset.ROIs,metrics);
