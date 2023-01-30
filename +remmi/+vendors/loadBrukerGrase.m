function [sigi,methpars,acqpars] = loadBrukerGrase(dataPath,methpars,acqpars)
% img = loadBrukerGrase(dataPath)
% loads & sorts raw data from remmiGRASE acquisitions 
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

isGRASE2 = contains(methpars.Method,'remmiGRASE2');
% isGRASE2 = true means the readout is bipolar

if isfield(methpars,'PVM_RareFactor')
    rarefactor = methpars.PVM_RareFactor;
else
    rarefactor = 1;
end

if isfield(methpars,'EffectiveTE')
    echotimes = methpars.EffectiveTE; % ms
else
    echotimes = methpars.PVM_EchoTime;
end

% Number of diffusion images
diffImgs = 1;
if isfield(methpars,'REMMI_DwiOnOff')
    if strcmp(methpars.REMMI_DwiOnOff,'Yes')
        diffImgs = methpars.PVM_DwNDiffExp;
    end
end

% Number of IR images (including MTIR)
irImgs = 1;
if isfield(methpars,'REMMI_MtIrOnOff')
    if strcmp(methpars.REMMI_MtIrOnOff,'Yes')
        irImgs = methpars.REMMI_NMtIr;
    end
end

% Number of MT images (MT offset)
mtImgs = 1;
if isfield(methpars,'REMMI_NMagTrans')
    if strcmp(methpars.PVM_MagTransOnOff,'On')
        mtImgs = methpars.REMMI_NMagTrans;
    end
end

% Number of recieve coils
ncoil = 1;
if isfield(methpars,'PVM_EncNReceivers')
    ncoil = methpars.PVM_EncNReceivers;
end

nslice = sum(methpars.PVM_SPackArrNSlices);
nreps = methpars.PVM_NRepetitions;
bsImgs = 1;

encmatrix = methpars.PVM_EncMatrix;
matrix = methpars.PVM_Matrix;
acqsize = acqpars.ACQ_size;
if length(encmatrix) < 3 
    encmatrix(3) = 1;
end
if length(matrix) < 3 
    matrix(3) = 1;
end
if length(acqsize) < 3 
    acqsize(3) = 1;
end

pe1table = methpars.PVM_EncSteps1;
pe1table = pe1table+floor(encmatrix(2)/2)+1;

if encmatrix(3) > 1
    pe2table = methpars.PVM_EncSteps2;
    pe2table = pe2table+floor(encmatrix(3)/2)+1;
else
    pe2table = 1;
end


fid=fopen([dataPath,'/fid']);
if (fid == -1)
    error('Cannot open fid file in %s', dataPath);
end

raw=fread(fid,'bit32'); %long=32-bit unsigned integer, signed=bit32
fclose(fid);

raw = reshape(raw,2,[]);
raw = squeeze(raw(1,:) + 1i*raw(2,:));

% Bruker requires reaodut lines to have memory alignment of 2^n 
roalign=length(raw)/ncoil/length(echotimes)/encmatrix(2)/encmatrix(3)/2/...
    diffImgs/irImgs/mtImgs/bsImgs/nreps/nslice;

ne = methpars.PVM_RareFactor*length(echotimes)+methpars.REMMI_NavEchoes;
n1 = ceil(acqsize(1)/2/128)*128;

sig = reshape(raw,n1,ncoil,ne,nslice,acqsize(2)/ne,acqsize(3),...
    diffImgs,irImgs,mtImgs,bsImgs,nreps);

% order now is [ro&grase ncoil echoTrain nslice pe1 pe2 diff ir 1, 1, nr]

% crop readout and reorder GRASE
sig = sig(1:acqsize(1)/2,:,:,:,:,:,:,:,:,:);

risetm = 0.145;

gfact = 1;
trueGraseFactor = methpars.REMMI_GraseFactor;
if isGRASE2
    ph0=(0:size(sig,1)-1)';
    ph0_off_corr = exp(1i*2*pi*ph0*methpars.PVM_ReadOffset/methpars.PVM_Fov(1)/2);
    sig = sig.*ph0_off_corr;
    gfact = 2;
    trueGraseFactor = 2*methpars.REMMI_GraseFactor-1;
else
    ph0_off_corr = 1;
end

nro_line = methpars.PVM_EncMatrix(1);
nstart = round(risetm/(1000/methpars.PVM_EffSWh/methpars.PVM_AntiAlias(1)));
nstart = nstart + round((0:trueGraseFactor-1)...
  *methpars.REMMI_GraseEchoSpacing/gfact/(1000/methpars.PVM_EffSWh/methpars.PVM_AntiAlias(1)));
nstart = nstart + (0:nro_line-1)';
sig = sig(nstart(:),:,:,:,:,:,:,:,:,:,:);
ne = methpars.PVM_RareFactor+methpars.REMMI_NavEchoes;
sig = reshape(sig,nro_line,trueGraseFactor,ncoil,...
  ne,nslice,acqsize(2)/ne,acqsize(3),diffImgs,irImgs,mtImgs,bsImgs,nreps);

if isGRASE2
    % reverse odd grase lines for bi polar readout
    sig(:,2:2:end,:) = sig(end:-1:1,2:2:end,:);
end

% order now is [ro grase ncoil echoTrain nslice pe1, pe2, diff, ir, 1, 1, nr]
proj = fftshift(fft(fftshift(sig,1)),1);


%% correct for phase variations down the echo train, if reference data exists
vals = remmi.util.strsplit(methpars.REMMI_ProcnoResult(2:end-1),',');
[fstudy,~] = fileparts(dataPath);
if ~strcmp(strtrim(vals{end-1}),'0')
    ph_fid = fullfile(fstudy,strtrim(vals{end-1}),'fid');
    fid=fopen(ph_fid);
    if (fid == -1)
        error('Cannot open fid file in %s', ph_fid);
    end

    raw_p=fread(fid,'bit32'); %long=32-bit unsigned integer, signed=bit32
    fclose(fid);

    raw_p = reshape(raw_p,2,[]);
    raw_p = squeeze(raw_p(1,:) + 1i*raw_p(2,:));


    sig_p = reshape(raw_p,n1,[]);
    sig_p = sig_p(1:acqpars.ACQ_size(1)/2,:,:,:);
    
    sig_p = sig_p.*ph0_off_corr;
    
    sig_p = sig_p(nstart(:),:);
    sig_p = reshape(sig_p,nro_line,trueGraseFactor,ncoil,...
      ne,nslice,[],1,diffImgs);
    sig_p = mean(sig_p,6);
    if isGRASE2
        sig_p(:,2:2:end,:) = sig_p(end:-1:1,2:2:end,:);
    end
    proj_p = fftshift(fft(fftshift(sig_p,1)),1);
    projcc = proj.*conj(proj_p)./abs(proj_p);
else
    projcc = proj;
end

%% navigator correction

projc = zeros(size(proj));
projc(:,:,:,1:2:end,:,:,:,:,:,:,:) = ...
    projcc(:,:,:,1:2:end,:,:,:,:,:,:,:);%.*exp(-1i*angle(projcc(:,:,:,end-1,:,:,:,:,:,:,:)));
projc(:,:,:,2:2:end,:,:,:,:,:,:,:) = ...
    projcc(:,:,:,2:2:end,:,:,:,:,:,:,:);%.*exp(-1i*angle(projcc(:,:,:,end  ,:,:,:,:,:,:,:)));

sig = ifftshift(ifft(ifftshift(projc,1)),1);
sig = sig(:,:,:,1:rarefactor*length(echotimes),:,:,:,:,:,:,:);

%% split rare & pe

% order now is [ro grase ncoil echoTrain nslice pe1, pe2, diff, ir, 1, 1, nr]
sig = reshape(sig,nro_line,trueGraseFactor,ncoil,...
  rarefactor,length(echotimes),nslice,acqsize(2)/ne,acqsize(3),...
  diffImgs,irImgs,mtImgs,bsImgs,nreps);
% labels = {'ro', 'grase', 'ncoil', 'rare', 'ne', 'ns', 'pe1', 'pe2', ...
%     'diff', 'ir', '1', '1', 'nr'};

% order now is [1 2 3 4 5 6 7, 8, diff, ir, 1, 1, nr]
ordr = [1 4 7 8 2 5 3 6 9 10 11 12 13];
sig = permute(sig,ordr);
% labels = labels(ordr);

% order now is [ro rare pe1 grase pe2 nslice ne ncoil diff, ir, 1, 1, nr]

sig = reshape(sig,[encmatrix,length(echotimes),ncoil,nslice,...
    diffImgs,irImgs,mtImgs,bsImgs,nreps]);

% use phase encode tables
sigi = zeros([encmatrix length(echotimes),ncoil,nslice,diffImgs,irImgs,mtImgs,bsImgs,nreps]);
sigi(:,pe1table,pe2table,:,:,:,:,:,:,:,:,:) = sig;

% reorder slices
sl_order = methpars.PVM_ObjOrderList + 1;
sigi(:,:,:,:,:,sl_order,:,:,:,:,:,:) = sigi;

% phase encode off isocenter shift 
ph1_offset = 0;
ph2_offset = 0;
if isfield(methpars,'PVM_EffPhase1Offset')
    ph1_offset = reshape(methpars.PVM_EffPhase1Offset,1,1,1,1,1,[]);
end
if isfield(methpars,'PVM_EffPhase2Offset')
    ph2_offset = reshape(methpars.PVM_EffPhase2Offset,1,1,1,1,1,[]);
end

if isGRASE2
    % RO shift for GRASE2
    ph0=(0:size(sigi,1)-1)';
    ph0_off_corr = exp(-1i*2*pi*ph0*methpars.PVM_ReadOffset/methpars.PVM_Fov(1)/2);
    sigi = sigi.*ph0_off_corr;
end

% PE1 shift
np = encmatrix(2);
line = reshape((1:np) - 1 - round(np/2),1,[]);
sigi = bsxfun(@times,sigi,exp(-1i*2*pi*bsxfun(@times,line,ph1_offset)/methpars.PVM_Fov(2)/methpars.PVM_AntiAlias(2)));

% PE2 shift
if length(methpars.PVM_EncMatrix) > 2
    np = encmatrix(3);
    line = reshape((1:np) - 1 - round(np/2),1,1,[]);
    sigi = bsxfun(@times,sigi,exp(-1i*2*pi*bsxfun(@times,line,ph2_offset)/methpars.PVM_Fov(3)/methpars.PVM_AntiAlias(3)));
end
