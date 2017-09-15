function process = dti()
% default recon + analysis pipeline for dti

% load in the default reconstruction pipeline
process = remmi.proc.recon();

% to do: add bmatrix
error('this is not complete')

% add dti
idx = numel(process)+1;
dti = remmi.dataset('dti');

process{idx}.name = 'dti';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.dtiAnalysis(a{:});
process{idx}.out = dti;