clear all

% full path to the study
study = 'data/klw_20140131_01.o61';

% list of experiments that contain mtir data to analyze
exps = 11:25;

imgset = remmi.loadImageData(study,exps);

%% Set a mask
imgset.mask = abs(imgset.img(:,:,:,1))./max(abs(imgset.img(:))) > 0.1;

%% Look at an example image and mask
figure(1)
imagesc(imgset.img(:,:,ceil(end/2),end))
axis image off
colormap gray

figure(2)
imagesc(imgset.mask(:,:,ceil(end/2)))
axis image off

%%
disp('Press any key to continue...')
pause

%% perform MTIR analysis
tic
mtirSet = remmi.mtirAnalysis(imgset);
toc

save mtir.mat mtirSet