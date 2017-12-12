clearvars

% List the study path and experiments to process
info.spath = './data/dti_mse_study';
info.exps = 30;

% specify where the data will be stored
ws = remmi.workspace('full_t2.mat',info);

% reconstruct the data
ws.images = remmi.recon(info);

% Set a mask based upon the first echo time image
ws.images = remmi.util.thresholdmask(ws.images);

% load the default metrics for mT2 analysis
metrics = remmi.mse.mT2options();

% add a spectrum to the output
metrics.S = @(out) out.S;

% Process multi-TE data
ws.epg = remmi.mse.mT2(ws.images,metrics);

% draw a few ROIS
opts.nROIs = 3;
ws.ROIs = remmi.roi.draw(ws.images,opts);

% Process ROI data
ws.ROI_epg = remmi.mse.mT2(ws.ROIs,metrics);
