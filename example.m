clearvars

%% input parameters
% data{1}.spath = ''; % optional path to the study
% data{1}.exps = []; % optional list experiments to process in study
data{1}.fname = 'remmi.mat'; % where to store the results

%% perform a basic basic reconstruction
process = remmi.proc.recon();

%% other example processes

% standard epg processing
% process = remmi.proc.epg();

% standard qmt processing
% process = remmi.proc.qmt();

% standard dti processing
% process = remmi.proc.dt();


%% process data
remmi(process,data);