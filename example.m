clearvars

idx = 0;

%% anatomical image
idx = idx + 1;
info{idx}.spath = ''; % optional path to the experimental study
info{idx}.exps = []; % optional list of experiments to process in the study
info{idx}.fname = 'anatomy.mat'; % where to store the results
info{idx}.proc = remmi.proc.recon(); % perform a standard reconstruction

%% epg experiment
idx = idx + 1;
info{idx}.spath = ''; 
info{idx}.exps = []; 
info{idx}.fname = 'epg.mat'; 
info{idx}.proc = remmi.proc.epg(); % use standard remmi epg processing

%% qmt experiment
idx = idx + 1;
info{idx}.spath = ''; 
info{idx}.exps = []; 
info{idx}.fname = 'qmt.mat'; 
info{idx}.proc = remmi.proc.qmt(); % use standard remmi qmt processing

%% t1 experiment
idx = idx + 1;
info{idx}.spath = ''; 
info{idx}.exps = []; 
info{idx}.fname = 't1.mat'; 
info{idx}.proc = remmi.proc.t1(); % use standard remmi qmt processing

%% dti experiment
idx = idx + 1;
info{idx}.spath = ''; 
info{idx}.exps = []; 
info{idx}.fname = 'dti.mat'; 
info{idx}.proc = remmi.proc.dti(); % standard remmi dti processing


%% process data
tic
remmi(info)
toc