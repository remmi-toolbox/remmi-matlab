function img = loadBruker(dataPath)
% img = loadBruker(dataPath)
% loads raw data from Bruker acquisitions & reconstructs images 
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

fid=fopen([dataPath,'/fid']);
if (fid == -1)
    error('Cannot open fid file in %s', dataPath);
end

raw=fread(fid,'bit32'); %long=32-bit unsigned integer, signed=bit32
fclose(fid);

% load a few parameters
methpath = fullfile(dataPath,'method');
methpars = remmi.vendors.parsBruker(methpath);


if isfield(methpars,'PVM_RareFactor')
    rarefactor = methpars.PVM_RareFactor;
else
    rarefactor = 1;
end

if isfield(methpars,'EffectiveTE')
    echotimes = methpars.EffectiveTE;
else
    echotimes = methpars.PVM_EchoTime;
end
nreps = methpars.PVM_NRepetitions;
encmatrix = methpars.PVM_Matrix;
if length(encmatrix) < 3 
    encmatrix(3) = 1;
end

pe1table = methpars.PVM_EncSteps1;
pe1table = pe1table+encmatrix(2)/2+1;

if encmatrix(3) > 1
    pe2table = methpars.PVM_EncSteps2;
    pe2table = pe2table+encmatrix(3)/2+1;
else
    pe2table = 1;
end

% Bruker requires reaodut lines to have memory alignment of 2^n 
roalign=length(raw)/length(echotimes)/encmatrix(2)/encmatrix(3)/2;

% combine real/imaginary
data = reshape(raw,2,length(raw)/2);
data = data(1,:) + 1i*data(2,:);

% at this point, the array index is [ro,rarefactor,echoes,pe1,pe2,nreps]
data = reshape(data,roalign,rarefactor,length(echotimes),encmatrix(2)/rarefactor,encmatrix(3),nreps);
data = permute(data,[1,2,4,5,3,6]); % format is [ro,rare,pe1,pe2,echoes,nreps]
data = reshape(data,roalign,encmatrix(2),encmatrix(3),length(echotimes),nreps);
data = data(1:encmatrix(1),:,:,:);
data(:,pe1table,pe2table,:,:) = data;

% reconstruct images
data = remmi.util.apodize(data,0.25);
data = fftshift(fftshift(fftshift(data,1),2),3);
img = fft(fft(data,encmatrix(1),1),encmatrix(2),2);
if encmatrix(3) > 1
    img = fft(img,encmatrix(3),3);
end
img = fftshift(fftshift(fftshift(img,1),2),3);


