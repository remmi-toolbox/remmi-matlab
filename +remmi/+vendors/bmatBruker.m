function bm = bmatBruker(pp)


dt = .012; % time resolution, ms
gamma = 42.576; % MHz/T
te = pp.te(1)*1000; % ms
tm = 0; % ms
gmax = pp.methpars.PVM_GradCalConst/gamma; % mT/m

% # of B0 images
nB0 = pp.methpars.PVM_DwAoImages; 
nB0end = pp.methpars.REMMI_DwAoImagesEnd;
nB0begin = nB0 - nB0end;

ref = remmi.util.strsplit(pp.methpars.RefPulse1(2:end-1),',');
refPulseDur = str2double(ref{1});
tssr = 2*pp.methpars.REMMI_EddyDelay + refPulseDur; % ms
gssr = pp.methpars.RefSliceGrad*gmax/100; % mT/m

tcrush = pp.methpars.EncGradDur; % ms
gcrush = pp.methpars.REMMI_ModSpoilerAmp(1)*gmax/100; % mT/m

% obtain normalized diffusion directions
dwdir = reshape(pp.methpars.PVM_DwGradVec,3,[]);
dro = dwdir(1,:);
dpe = -dwdir(2,:);
dsl = dwdir(3,:);

if strcmpi(pp.methpars.REMMI_DwGradPolarity,'Yes')
    dro = [dro, -dro];
    dpe = [dpe, -dpe];
    dsl = [dsl, -dsl];
    
    dro = repmat(dro,[1 pp.methpars.PVM_NRepetitions/2]);
    dpe = repmat(dpe,[1 pp.methpars.PVM_NRepetitions/2]);
    dsl = repmat(dsl,[1 pp.methpars.PVM_NRepetitions/2]);
else
    dro = repmat(dro,[1 pp.methpars.PVM_NRepetitions]);
    dpe = repmat(dpe,[1 pp.methpars.PVM_NRepetitions]);
    dsl = repmat(dsl,[1 pp.methpars.PVM_NRepetitions]);
end

% diffusion gradients
gdiff = gmax; % pp.methpars.PVM_DwGradAmp*gmax/100; % mT/m
bigD = pp.methpars.PVM_DwGradSep; % ms
litD = pp.methpars.PVM_DwGradDur; % ms

if ~isfield(pp.methpars,'REMMI_DwWaveType') || strcmp(pp.methpars.REMMI_DwWaveType,'Pulsed_Gradient')
    rwave = ones(1,round(litD/dt));
    pwave = ones(1,round(litD/dt));
    swave = ones(1,round(litD/dt));
else
    rwave = pp.methpars.REMMI_DwWaveR;
    pwave = pp.methpars.REMMI_DwWaveP;
    swave = pp.methpars.REMMI_DwWaveS;
end

for n=1:length(dro)
    t = 0:dt:(te+tm);
    Gr = zeros(size(t));
    Gp = zeros(size(t));
    Gs = zeros(size(t));

    % 180 slice select and crusher
    mask = (t>te/2-tssr/2-tcrush) & (t<=te/2);
    Gs(mask) = gcrush;
    mask = (t>te/2-tssr/2) & (t<=te/2);
    Gs(mask) = gssr;

    mask = (t<te/2+tm+tssr/2+tcrush) & (t>=te/2+tm);
    Gs(mask) = -gcrush;
    mask = (t<te/2+tm+tssr/2) & (t>=te/2+tm);
    Gs(mask) = -gssr;

    % read out direction
%     mask = (t>te/2-bigD/2-litD/2+tm/2) & (t<te/2-bigD/2+litD/2+tm/2);
%     Gr(mask) = gdiff*dro(n).*rwave;
%     Gp(mask) = gdiff*dpe(n).*rwave;
%     Gs(mask) = gdiff*dsl(n).*rwave;
% 
%     mask = (t>te/2+bigD/2-litD/2+tm/2) & (t<te/2+bigD/2+litD/2+tm/2);
%     Gr(mask) = -gdiff*dro(n).*rwave;
%     Gp(mask) = -gdiff*dpe(n).*rwave;
%     Gs(mask) = -gdiff*dsl(n).*rwave;

    [~,it0] = min(abs(t-(te/2-bigD/2-litD/2+tm/2)));
    Gr(it0:it0+length(rwave)-1) = gdiff*dro(n).*rwave;
    Gp(it0:it0+length(rwave)-1) = gdiff*dpe(n).*rwave;
    Gs(it0:it0+length(rwave)-1) = gdiff*dsl(n).*rwave;

    [~,it0] = min(abs(t-(te/2+bigD/2-litD/2+tm/2)));
    Gr(it0:it0+length(rwave)-1) = -gdiff*dro(n).*rwave;
    Gp(it0:it0+length(rwave)-1) = -gdiff*dpe(n).*rwave;
    Gs(it0:it0+length(rwave)-1) = -gdiff*dsl(n).*rwave;

    G = [Gr;Gp;Gs];

%     plot(t,G')
%     pause();

    % calculate the b-matrix
    k = cumsum(G,2)*dt*gamma*2*pi/1000; % 1/mm
    b = zeros(3,3);
    for m=1:size(k,2)
        b = b + k(:,m)*k(:,m)';
    end
    %bm(:,:,n) = b*dt/1000; % s/mm^2

    bm(:,n) = [diag(b);diag(b,-1);diag(b,-2);1000/dt]*dt/1000; % s/mm^2
end

