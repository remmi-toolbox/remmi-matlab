clearvars

%% read in & reconstruct image data
imgset = remmi.loadImageData();

%% Set a mask based upon the last inversion image

% which dimension is IR?
i = find(strcmp(imgset.labels,'IR'));
img = remmi.util.slice(imgset.img,i,size(imgset.img,i));

% create a threshold mask
imgset.mask = abs(img)./max(abs(img(:))) > 0.1;

%% process MTIR
qmt = remmi.mtirAnalysis(mtir);

%% save datasets
save(['easy_mt_' datestr(now,'yyyy.mm.dd.HH.MM.SS') '.mat'])
