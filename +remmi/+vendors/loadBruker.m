function datai = loadBruker(dataPath,methpars)
% img = loadBruker(dataPath)
% loads raw data from Bruker acquisitions & reconstructs images 
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if ~exist('methpars','var')
    % load a few parameters
    methpath = fullfile(dataPath,'method');
    methpars = remmi.vendors.parsBruker(methpath);
end

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

% Number of BsB1 images
bsImgs = 1;
if isfield(methpars,'REMMI_BsB1OnOff')
    if strcmp(methpars.REMMI_BsB1OnOff,'On')
        bsImgs = 2;
    end
end

% Number of recieve coils
ncoil = 1;
if isfield(methpars,'PVM_EncNReceivers')
    ncoil = methpars.PVM_EncNReceivers;
end

nslice = sum(methpars.PVM_SPackArrNSlices);
nreps = methpars.PVM_NRepetitions;

encmatrix = methpars.PVM_EncMatrix;
matrix = methpars.PVM_Matrix;
if length(encmatrix) < 3 
    encmatrix(3) = 1;
end
if length(matrix) < 3 
    matrix(3) = 1;
end

pe1table = methpars.PVM_EncSteps1;
pe1table = pe1table+floor(matrix(2)/2)+1;

if encmatrix(3) > 1
    pe2table = methpars.PVM_EncSteps2;
    pe2table = pe2table+floor(matrix(3)/2)+1;
else
    pe2table = 1;
end

fid=fopen([dataPath,'/fid']);

if (fid == -1)
    fid=fopen([dataPath,'/rawdata.job0']); % PV360 and others (?)
end

if (fid == -1)
    error('Cannot open fid file in %s', dataPath);
end

raw=fread(fid,'bit32'); %long=32-bit unsigned integer, signed=bit32
fclose(fid);

% Bruker requires reaodut lines to have memory alignment of 2^n 
roalign=length(raw)/ncoil/length(echotimes)/encmatrix(2)/encmatrix(3)/2/...
    diffImgs/irImgs/mtImgs/bsImgs/nreps/nslice;

% if reference phase data exists, read it in
ph_ref0 = zeros(1,rarefactor,1,1,length(echotimes),ncoil,nslice,diffImgs,1,1,1,nreps);
ph_ref1 = zeros(1,rarefactor,1,1,length(echotimes),ncoil,nslice,diffImgs,1,1,1,nreps);
if isfield(methpars,'REMMI_ProcnoResult')
    vals = remmi.util.strsplit(methpars.REMMI_ProcnoResult(2:end-1),',');
    [fstudy,~] = fileparts(dataPath);
    if ~strcmp(strtrim(vals{end-1}),'0')
        ph_path = fullfile(fstudy,strtrim(vals{end-1}));
        ph_fid = fopen(fullfile(ph_path,'fid'));
        if ph_fid < 0
            ph_fid = fopen(fullfile(fstudy,strtrim(vals{end-1}),'rawdata.job0'));
        end
        if ph_fid < 0
            warning('Phase reference scan not found');
        else
            ph_raw = fread(ph_fid,'bit32');
            fclose(ph_fid);
            %ph_pars = remmi.vendors.parsBruker(fullfile(ph_path,'method'));

            % real + imaginary
            ph_raw = reshape(ph_raw,2,length(ph_raw)/2);
            ph_raw = ph_raw(1,:) + 1i*ph_raw(2,:);

            % set format to [readout, echo, etc]
            % [ro,ncoil,rarefactor,echoes,slices,pe1,pe2,diff,mtir,nreps]
            ph_raw = reshape(ph_raw,roalign,ncoil,rarefactor*length(echotimes),[],nslice, ...
                diffImgs,1,1,1,nreps);
            
            ph_raw = permute(ph_raw,[1 3 4 2 5 6 7 8:12]);
            % order is now [ro, echo train, navg, ncoil, nslice, ndiff, ?,
            % ?, ?, rep]

            % bruker encoding workaround
            ph_raw = sum(ph_raw,3);
            ph_raw = reshape(ph_raw,[],rarefactor*length(echotimes),ncoil,nslice, ...
                diffImgs,1,1,1,nreps);

            ph_raw = ph_raw(1:encmatrix(1),:);

            % phase correction
            [ph_ref0,ph_ref1] = dwi_phase_corr(ph_raw);

            ph_ref0 = reshape(ph_ref0,[1 rarefactor 1 1 length(echotimes) ...
                ncoil nslice diffImgs 1 1 nreps]);
            ph_ref1 = reshape(ph_ref1,[1 rarefactor 1 1 length(echotimes) ...
                ncoil nslice diffImgs 1 1 nreps]);
        end
    end
end

% combine real/imaginary
data = reshape(raw,2,length(raw)/2);
data = data(1,:) + 1i*data(2,:);

% at this point, the array index is : 
% [ro,ncoil,rarefactor,echoes,slices,pe1,pe2,diff,mtir,,mt,BS,nreps]
data = reshape(data,roalign,ncoil,rarefactor,length(echotimes),nslice,...
    encmatrix(2)/rarefactor,encmatrix(3),diffImgs,irImgs,mtImgs,bsImgs,nreps);

% reorder
data = permute(data,[1,3,6,7,4,2,5,8:ndims(data)]);
data = remmi.util.slice(data,1,1:encmatrix(1));
% format is now [ro,rare,pe1,pe2,echoes,coils,slices,diffImgs,irImgs,mtImgs,nreps]

% move to projection space
proj = fftshift(fft(fftshift(data,1)),1);

% correct for 0th & first order phase
proj = bsxfun(@times,proj,exp(-1i*(...
    bsxfun(@plus, ph_ref0, bsxfun(@times,(1:encmatrix(1))',ph_ref1)))));

% back into full fourier space
data = ifftshift(ifft(ifftshift(proj,1)),1);

% use phase encode tables
data = reshape(data,encmatrix(1),encmatrix(2),encmatrix(3),length(echotimes),...
    ncoil,nslice,diffImgs,irImgs,mtImgs,bsImgs,nreps);
datai = zeros([matrix length(echotimes),ncoil,nslice,diffImgs,irImgs,mtImgs,bsImgs,nreps]);
datai(:,pe1table,pe2table,:,:,:,:,:,:,:,:,:) = data;

% reorder slices
sl_order = methpars.PVM_ObjOrderList + 1;
datai(:,:,:,:,:,sl_order,:,:,:,:,:,:) = datai;

% flip odd echoes in gradient echo sequences
if methpars.PVM_NEchoImages>1 && ~isfield(methpars,'RefPulse1')
    % no refocusing pulse. This must be a gradient echo sequence. 
    if isfield(methpars,'EchoAcqMode')
        if strcmp(methpars.EchoAcqMode,'allEchoes')
            disp('fliping...')
            datai(:,:,:,2:2:end,:,:,:,:,:,:,:) = datai(end:-1:1,:,:,2:2:end,:,:,:,:,:,:,:);
        end
    else
        disp('fliping...')
        datai(:,:,:,2:2:end,:,:,:,:,:,:,:) = datai(end:-1:1,:,:,2:2:end,:,:,:,:,:,:,:);
    end
end

% phase encode off isocenter shift 
ph1_offset = 0;
ph2_offset = 0;
if isfield(methpars,'PVM_EffPhase1Offset')
    ph1_offset = reshape(methpars.PVM_EffPhase1Offset,1,1,1,1,1,[]);
end
if isfield(methpars,'PVM_EffPhase2Offset')
    ph2_offset = reshape(methpars.PVM_EffPhase2Offset,1,1,1,1,1,[]);
end

% PE1 shift
np = methpars.PVM_Matrix(2);
line = reshape((1:np) - 1 - round(np/2),1,[]);
datai = bsxfun(@times,datai,exp(-1i*2*pi*bsxfun(@times,line,ph1_offset)/methpars.PVM_Fov(2)));

% PE2 shift
if length(methpars.PVM_EncMatrix) > 2
    np = methpars.PVM_EncMatrix(3);
    line = reshape((1:np) - 1 - round(np/2),1,1,[]);
    datai = bsxfun(@times,datai,exp(-1i*2*pi*bsxfun(@times,line,ph2_offset)/methpars.PVM_Fov(3)));
end

end

function [ph0,ph1] = dwi_phase_corr(raw)

proj = fftshift(fft(fftshift(raw,1)),1);

ph0 = zeros(size(raw,2),1);
ph1 = zeros(size(raw,2),1);

p1 = proj(:,1);
for n=2:size(proj,2)
    pn = proj(:,n);
    mask = abs(pn)/max(abs(pn)) > 0.1;
    ph_diff = pn./p1;
    
    idx = 1:length(pn);
    phw = unwrap(angle(ph_diff(mask)));
    ph = remmi.util.linfitfast(idx(mask)',phw,abs(pn(mask)));
    ph0(n) = ph(2);
    ph1(n) = ph(1);
end

end

