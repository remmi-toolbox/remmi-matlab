clearvars

%% read in & reconstruct image data
imgset = remmi.loadImageData();

%% Set a mask based upon the first echo time image

% which dimension is NE?
i = find(strcmp(imgset.labels,'NE'));
te1img = remmi.util.slice(imgset.img,i,1);

% create a threshold mask
imgset.mask = abs(te1img)./max(abs(te1img(:))) > 0.1;

%% Process multi-TE data
t2set = remmi.T2Analysis(imgset);

%% save datasets
save(['easy_t2_' datestr(now,'yyyy.mm.dd.HH.MM.SS') '.mat'])
