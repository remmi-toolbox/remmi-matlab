function process = dti()
% default recon + analysis pipeline for dti

% load in the default reconstruction pipeline
process = remmi.proc.recon();

% add bmatrix
idx = numel(process)+1;

process{idx}.name = 'bmatrix';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.util.addbmatrix(a{:});
process{idx}.out = process{idx-1}.out;

% add dti
idx = idx+1;
dti = remmi.dataset('dti');

process{idx}.name = 'dti';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.dtiAnalysis(a{:});
process{idx}.out = dti;