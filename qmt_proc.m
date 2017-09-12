clear all

%% select study
idx = 1;
spath = remmi.dataset('spath');

process{idx}.name = 'study';
process{idx}.in = {};
process{idx}.function = @(x) uigetdir([],'Select study directory');
process{idx}.out = spath;
process{idx}.interact = true;

%% select experiments
idx = idx+1;
exps = remmi.dataset('exps');

process{idx}.name = 'exp';
process{idx}.in = {spath};
process{idx}.function = @(a) remmi.util.selectexp(a{:});
process{idx}.out = exps;
process{idx}.interact = true;

%% reconstruction
idx = idx+1;
imgset = remmi.dataset('images');

process{idx}.name = 'recon';
process{idx}.in = {spath,exps};
process{idx}.function = @(a) remmi.loadImageData(a{:});
process{idx}.out = imgset;
process{idx}.interact = false;

%% mask
idx = idx+1;

process{idx}.name = 'mask';
process{idx}.in = {imgset};
process{idx}.function = @(a) remmi.util.thresholdmask(a{:});
process{idx}.out = imgset;
process{idx}.interact = false;

%% mtir
idx = idx+1;
qmt = remmi.dataset('qmt');

process{idx}.name = 'qmt';
process{idx}.in = {imgset};
process{idx}.function = @(a) remmi.mtirAnalysis(a{:});
process{idx}.out = qmt;
process{idx}.interact = false;

%% save the processing pipeline
save qmt process