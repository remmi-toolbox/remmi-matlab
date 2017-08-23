clearvars

%% read in & reconstruct image data
imgset = remmi.loadImageData();

% and b-matrix
imgset.bmat = remmi.vendors.bmatBruker(imgset.pars);

%% Set a mask based upon the first diffusion-weighted image

% which dimension is diffusion-weighting?
i = find(ismember(imgset.labels,{'DW','NR'}));
b0img = remmi.util.slice(imgset.img,i,1);

% create a threshold mask
imgset.mask = abs(b0img)./max(abs(b0img(:))) > 0.1;

%% perform MTIR analysis
dtiSet = remmi.dtiAnalysis(imgset);

%% save datasets
save(['easy_dti_' datestr(now,'yyyy.mm.dd.HH.MM.SS') '.mat'])

