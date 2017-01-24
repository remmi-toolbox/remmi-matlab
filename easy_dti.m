clear all

% full path to the study
study = '/Users/kevinharkins/Data/2017/01.24/dtiMSE/20170121_091727_CuS_ball_phantom_1_2';

% list of experiments that contain mtir data to analyze
exps = 15;

imgset = remmi.loadImageData(study,exps);
imgset.bmat = remmi.vendors.bmatBruker(imgset.pars);

%% Set a mask
imgset.mask = abs(imgset.img(:,:,:,1))./max(abs(imgset.img(:))) > 0.1;

%% Look at an example image and mask
figure(1)
imagesc(imgset.img(:,:,ceil(end/2),1,1))
axis image off
colormap gray

figure(2)
imagesc(imgset.mask(:,:,ceil(end/2)))
axis image off

%% perform MTIR analysis
tic
dtiSet = remmi.dtiAnalysis(imgset);
toc

save dti.mat dtiSet