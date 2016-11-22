clear all

% path to the study
study = 'data/epgtest';
exps = 5;

imgset = remmi.loadImageData(study,exps);

%% Set a mask
imgset.mask = abs(imgset.img(:,:,:,1))./max(abs(imgset.img(:))) > 0.1;

%% Process multi-TE data
t2set = remmi.T2Analysis(imgset);

%%
figure(1)
imagesc(t2set.T2);
axis image off
colormap jet
colorbar