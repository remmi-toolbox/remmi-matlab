function process = epg()
% default recon + analysis pipeline for mtir-based qmt

% load in the default reconstruction pipeline
process = remmi.proc.recon();

% add epg
idx = numel(process)+1;
epg = remmi.dataset('epg');

process{idx}.name = 'epg';
process{idx}.in = {process{idx-1}.out};
process{idx}.function = @(a) remmi.T2Analysis(a{:});
process{idx}.out = epg;