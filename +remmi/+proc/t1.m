function process = t1()
% default recon + analysis pipeline for mtir-based qmt

% load in the default reconstruction pipeline
process = remmi.proc.recon();

% add qmt
idx = numel(process)+1;
t1 = remmi.dataset('t1');

process{idx}.name = 't1';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.irAnalysis(a{:});
process{idx}.out = t1;