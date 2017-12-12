clearvars

% List the study path and experiments to process
info.spath = './data/mtstudy';
info.exps = 29;

% specify where the data will be stored
ws = remmi.workspace('easy_mtir.mat');

% perform mtir analysis
ws.mtir = remmi.ir.qmt(info);
