function qMTout = qmt(dset,varargin)
% mtirSet = remmi.ir.qmt(dset,name,init,output) performs MTIR analysis on
% the data in dset:
%
%       dset.(name) = data to process
%       dset.mask = mask for processing data
%       dset.pars = basic remmi parameter set including ti & td.
%       dset.labels = cell array of labels to dset.img dimensions
%
%       **NB dset is often dset.images and the data to be processed is
%           often dset.images.img
%
%       if dset or dset.(name) is not given, default reconstruction and
%       thresholding methods are called
%
%       name = name of field in dset to fit. Default is 'img'
%
%       init = inital values and lower & upper bounds used for fitting
%         [M0a,M0b,kmf,1/T1,inv_eff]
%
%       output = a structure with field names matching those to be
%           returned. The default maps are M0a, M0b, BPF, T1, and inv_eff.
%           To select different outputs, pass in 'output' with any of
%           the following field names:
%               M0a: amplitude of the free water equilibrium magnetization
%               M0b: amplitude of the bound proton equilibrium magnetization
%               PSR: M0b/M0a
%               BPF: M0b/(M0a+M0b)
%               kmf: Exchange rate constant, bound-to-free pool
%               T1: Free water longitudinal relaxation time constant
%               inv_eff: cos of effective inversion pulse flip angle
%
%           For example, "output = struct('M0a',[],'M0b',[],'BPF',[])",
%           then call "remmi.ir.qmt(dset.images,'img',init,output)"
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% load in the dataset

[name,init,output] = setoptions(varargin{:});

if ~exist('dset','var')
  dset = struct();
end

if ~isfield(dset,name) || isempty(dset.(name))
  dset = remmi.util.thresholdmask(remmi.recon(dset));
end

sz = size(dset.(name));

% what dimension is MT encoding?
mtDim = ismember(dset.labels,'IR');

if ~any(mtDim)
  error('Data set does not contain multiple inversion times');
end

% load in the needed parameters
ti = dset.pars.ti; % sec
td = dset.pars.td; % sec

if numel(ti)<6
  error('There are not enough inversion times in this datatset for MTIR analysis')
end

if numel(ti) ~= sz(mtDim)
  error('The number of inversion times does not match the dataset dimenions')
end

% define a mask if one is not given
if isfield(dset,'mask')
  mask = squeeze(dset.mask);
  
  % apply the mask across all non-MT dimensions
  mask = bsxfun(@times,mask,ones(sz(~mtDim)));
else
  mask = squeeze(true(sz(~mtDim)));
end


% initialize the output dimensions
M0a = zeros(size(mask));
M0b = zeros(size(mask));
PSR = zeros(size(mask));
BPF = zeros(size(mask));
kmf = zeros(size(mask));
T1 = zeros(size(mask));
inv_eff = zeros(size(mask));

tot_evals = sum(mask(:));
evals = 0;

% make the MT dimension the first index.
idx = 1:ndims(dset.(name));
data = permute(dset.(name),[idx(mtDim) idx(~mtDim)]);

warning('off','MATLAB:singularMatrix')

fop  = optimset('lsqnonlin');
fop = optimset(fop,'display','off','TolX',1e-6,'TolFun',1e-6);
% MDD lowered Tol from 1e-3 and 1e-4 after some fitting issues

fprintf('%3.0f %% done...',0);
tic

for n=1:1:numel(mask) % 
  if mask(n)
    
    sig = squeeze(abs(data(:,n)));
    
    % MDD prior version did not allow user to pass in the init vals
    if exist('init','var')
      b0 = init.b0;
      lb = init.lb;
      ub = init.ub;
    else
      % initial guess & bounds
      b0 = init.b0(sig);
      lb = init.lb(sig);
      ub = init.ub(sig);
    end
    
    
    % fit the data
    [b,~,res,~,~,~,jac] = ...
      lsqnonlin(@(x) remmi.ir.sir(x,ti',td)-sig,b0,lb,ub,fop);
    
    % compute output parameters
    M0a(n) = b(1);
    M0b(n) = b(2);
    PSR(n) = b(2)/b(1);
    BPF(n) = b(2)/(b(1)+b(2));
    kmf(n) = b(3);
    T1(n) = 1/b(4);
    inv_eff(n) = b(5);
    
    evals = evals+1;
    if ~mod(evals,round(tot_evals/20))
      tstep = toc;
      fprintf('%3.0f %% done, 5%% step time = %4f s...\n',...
        evals/tot_evals*100,tstep);
      tic
    end
  end
end

warning('on','MATLAB:singularMatrix')

outfields = fieldnames(output);
Nout = length(outfields);

if isfield(output,'M0a')
  qMTout.M0a = M0a;
end
if isfield(output,'M0b')
  qMTout.M0b = M0b;
end
if isfield(output,'PSR')
  qMTout.PSR = PSR;
end
if isfield(output,'BPF')
  qMTout.BPF = BPF;
end
if isfield(output,'kmf')
  qMTout.kmf = kmf;
end
if isfield(output,'T1')
  qMTout.T1 = T1;
end
if isfield(output,'inv_eff')
  qMTout.inv_eff = inv_eff;
end

end

function [name,init,output] = setoptions(name,init,output)

if ~exist('name','var') || isempty(name)
  name = 'img';
end

if ~exist('init','var') || isempty(init)
  init.b0 = str2func('@(sig) [max(sig), max(sig)/10,  25,   2, max(-1,-sig(1)/sig(end))]');
  init.lb = str2func('@(sig) [       0,           0,   2,   0,  -1]');
  init.ub = str2func('@(sig) [     inf,         inf, 200, inf,   1]');
end

if ~exist('output','var')
  output = struct('M0a',[],'M0b',[],'BPF',[],'T1',[],'inv_eff',[]);
end

end