clear all

% path to the study
study = 'data/klw_20140131_01.o61';

% list of experiment numbers that contain mtir data to analyze
exps = 11:25;

imgset = remmi.loadImageData(study,exps);

%% Set a mask
imgset.mask = abs(imgset.img(:,:,:,1))./max(abs(imgset.img(:))) > 0.1;

%% perform MTIR analysis
mtirSet = remmi.mtirAnalysis(imgset);

save mtir.mat mtirSet