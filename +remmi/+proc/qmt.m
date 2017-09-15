function process = qmt()
% default recon + analysis pipeline for mtir-based qmt

% load in the default reconstruction pipeline
process = remmi.proc.recon();

% add qmt
idx = numel(process)+1;
qmt = remmi.dataset('qmt');

process{idx}.name = 'qmt';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.mtirAnalysis(a{:});
process{idx}.out = qmt;