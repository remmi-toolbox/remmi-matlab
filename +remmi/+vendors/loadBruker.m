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

% if reference phase data exists, read it in
ph_ref0 = zeros(1,rarefactor,1,1,length(echotimes),nslice,diffImgs,1,1,nreps);
ph_ref1 = zeros(1,rarefactor,1,1,length(echotimes),nslice,diffImgs,1,1,nreps);
if isfield(methpars,'REMMI_ProcnoResult')
    vals = remmi.util.strsplit(methpars.REMMI_ProcnoResult(2:end-1),',');
    [fstudy,~] = fileparts(dataPath);
    if ~strcmp(strtrim(vals{end-1}),'0')
        ph_fid = fopen(fullfile(fstudy,strtrim(vals{end-1}),'fid'));
        if ph_fid < 0
            warning('Phase reference scan not found');
        else
            ph_raw = fread(ph_fid,'bit32');
            fclose(ph_fid);

            % real + imaginary
            ph_raw = reshape(ph_raw,2,length(ph_raw)/2);
            ph_raw = ph_raw(1,:) + 1i*ph_raw(2,:);

            % related to bruker encoding workaround
            navg = max(8/rarefactor*length(echotimes),1);

            % set format to [readout, echo, etc]
            ph_raw = reshape(ph_raw,[],rarefactor*length(echotimes),navg,nslice, ...
                diffImgs,1,1,nreps);

            % bruker encoding workaround
            ph_raw = sum(ph_raw,3);
            ph_raw = reshape(ph_raw,[],rarefactor*length(echotimes),nslice, ...
                diffImgs,1,1,nreps);

            ph_raw = ph_raw(1:encmatrix(1),:);

            % phase correction
            [ph_ref0,ph_ref1] = dwi_phase_corr(ph_raw);

            ph_ref0 = reshape(ph_ref0,[1 rarefactor 1 1 length(echotimes) ...
                nslice diffImgs 1 1 nreps]);
            ph_ref1 = reshape(ph_ref1,[1 rarefactor 1 1 length(echotimes) ...
                nslice diffImgs 1 1 nreps]);
        end
    end
end


fid=fopen([dataPath,'/fid']);
if (fid == -1)
    error('Cannot open fid file in %s', dataPath);
end

raw=fread(fid,'bit32'); %long=32-bit unsigned integer, signed=bit32
fclose(fid);

% Bruker requires reaodut lines to have memory alignment of 2^n 
roalign=length(raw)/length(echotimes)/encmatrix(2)/encmatrix(3)/2/...
    diffImgs/irImgs/mtImgs/nreps/nslice;

% combine real/imaginary
data = reshape(raw,2,length(raw)/2);
data = data(1,:) + 1i*data(2,:);

% at this point, the array index is : 
% [ro,rarefactor,echoes,slices,pe1,pe2,diff,mtir,nreps]
data = reshape(data,roalign,rarefactor,length(echotimes),nslice,...
    encmatrix(2)/rarefactor,encmatrix(3),diffImgs,irImgs,mtImgs,nreps);

% reorder
data = permute(data,[1,2,5,6,3,4,7:ndims(data)]);
data = remmi.util.slice(data,1,1:encmatrix(1));
% format is now [ro,rare,pe1,pe2,echoes,slices,diffImgs,irImgs,mtImgs,nreps]

% move to projection space
proj = fftshift(fft(fftshift(data,1)),1);

% correct for 0th & first order phase
proj = bsxfun(@times,proj,exp(-1i*(...
    bsxfun(@plus, ph_ref0, bsxfun(@times,(1:encmatrix(1))',ph_ref1)))));

% back into full fourier space
data = ifftshift(ifft(ifftshift(proj,1)),1);

% use phase encode tables
data = reshape(data,encmatrix(1),encmatrix(2),encmatrix(3),length(echotimes),...
    nslice,diffImgs,irImgs,mtImgs,nreps);
datai = zeros([matrix length(echotimes),nslice,diffImgs,irImgs,mtImgs,nreps]);
datai(:,pe1table,pe2table,:,:,:,:,:,:,:,:) = data;

% flip odd echoes in gradient echo sequences
if methpars.PVM_NEchoImages>1 && ~isfield(methpars,'RefPulse1')
    % no refocusing pulse. This must be a gradient echo sequence. 
    if isfield(methpars,'EchoAcqMode')
        if strcmp(methpars.EchoAcqMode,'allEchoes')
            disp('fliping...')
            datai(:,:,:,2:2:end,:,:,:,:,:,:) = datai(end:-1:1,:,:,2:2:end,:,:,:,:,:,:);
        end
    end
end

try
    % PE1 shift
    np = methpars.PVM_Matrix(2);
    line = reshape((1:np) - 1 - round(np/2),1,[]);
    
    % if multi-slice, make the phase offset the correct size
    ph1_offset = reshape(methpars.PVM_EffPhase1Offset,[1,1,1,1,nslice]);
    ph2_offset = reshape(methpars.PVM_EffPhase2Offset,[1,1,1,1,nslice]);
    
    datai = bsxfun(@times,datai,exp(-1i*2*pi*bsxfun(@times,line,ph1_offset)/methpars.PVM_Fov(2)));

    % PE2 shift
    if length(methpars.PVM_EncMatrix) > 2
        np = methpars.PVM_EncMatrix(3);
        line = reshape((1:np) - 1 - round(np/2),1,1,[]);
        datai = bsxfun(@times,datai,exp(-1i*2*pi*bsxfun(@times,line,ph2_offset)/methpars.PVM_Fov(3)));
    end
catch
    % todo: implement PE offset correction for PV5
    warning('PE offsets are uncorrected');
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

