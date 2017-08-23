function bm = bmatBruker(pp)


dt = .004; % time resolution, ms
gamma = 42.576; % MHz/T
te = pp.te(1); % ms
tm = 0; % ms
gmax = pp.methpars.PVM_GradCalConst/gamma; % mT/m

% # of B0 images
nB0 = pp.methpars.PVM_DwAoImages; 
nB0end = pp.methpars.REMMI_DwAoImagesEnd;
nB0begin = nB0 - nB0end;

ref = strsplit(pp.methpars.RefPulse1(2:end-1),',');
refPulseDur = str2double(ref{1});
tssr = 2*pp.methpars.REMMI_EddyDelay + refPulseDur; % ms
gssr = pp.methpars.RefSliceGrad*gmax/100; % mT/m

tcrush = pp.methpars.EchoSpoilDur; % ms
gcrush = pp.methpars.REMMI_ModSpoilerAmp(1)*gmax/100; % mT/m

% obtain normalized diffusion directions
dwdir = reshape(pp.methpars.PVM_DwDir,3,[]);
dro = [zeros(1,nB0begin) dwdir(1,:) zeros(1,nB0end)];
dpe = [zeros(1,nB0begin) -dwdir(2,:) zeros(1,nB0end)];
dsl = [zeros(1,nB0begin) dwdir(3,:) zeros(1,nB0end)];

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
gdiff = pp.methpars.PVM_DwGradAmp*gmax/100; % mT/m
bigD = pp.methpars.PVM_DwGradSep; % ms
litD = pp.methpars.PVM_DwGradDur; % ms

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
    mask = (t>te/2-bigD/2-litD/2+tm/2) & (t<te/2-bigD/2+litD/2+tm/2);
    Gr(mask) = gdiff*dro(n);
    mask = (t>te/2+bigD/2-litD/2+tm/2) & (t<te/2+bigD/2+litD/2+tm/2);
    Gr(mask) = -gdiff*dro(n);
    
    % phase encode direction
    mask = (t>te/2-bigD/2-litD/2+tm/2) & (t<te/2-bigD/2+litD/2+tm/2);
    Gp(mask) = +gdiff*dpe(n);
    mask = (t>te/2+bigD/2-litD/2+tm/2) & (t<te/2+bigD/2+litD/2+tm/2);
    Gp(mask) = -gdiff*dpe(n);
    
    % slice select direction
    mask = (t>te/2-bigD/2-litD/2+tm/2) & (t<te/2-bigD/2+litD/2+tm/2);
    Gs(mask) = gdiff*dsl(n);
    mask = (t>te/2+bigD/2-litD/2+tm/2) & (t<te/2+bigD/2+litD/2+tm/2);
    Gs(mask) = -gdiff*dsl(n);
    
    G = [Gr;Gp;Gs];
    
    plot(G')
    pause();
    
    % calculate the b-matrix
    k = cumsum(G,2)*dt*gamma*2*pi/1000; % 1/mm
    b = zeros(3,3);
    for m=1:size(k,2)
        b = b + k(:,m)*k(:,m)';
    end
    %bm(:,:,n) = b*dt/1000; % s/mm^2
    
    bm(:,n) = [diag(b);diag(b,-1);diag(b,-2);1]*dt/1000; % s/mm^2
    
end

