function Mz = sir(X,ti,td)
% function Er = sir(X,ti,td) solves 2-compartment bloch equations
% compatible with Single Inversion Recovery qMT analysis
%   X(1) = signal of the free water pool 
%   X(2) = signal of the bound water pool 
%   X(3) = exchange rate from macro to water pools (Hz)
%   X(4) = R1 of free water (Hz)
%   X(5) = inversion efficiency 
%   ti = list of inversion times
%   td = a single delay time. tr = ti+td
%   
%   R1 of the bound pool is assumed to be 1 Hz
%
% by Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

Moa = X(1); % free water pool
Mob = X(2); % macro pool 
kba = X(3); % exchange rate from macro to water
R1a = X(4); % R1 of free water (aka the measured R1)
R1b = 1; % R1 of bound water, assumed to be 1 /s.
alpha_a = X(5); % inv efficiency 
alpha_b = 0.83;

Mo = [Moa;Mob];
kab = kba*Mob/Moa;
L1 = [-(R1a+kab) kba; kab -(R1b+kba)];

N = length(ti);
Mz = zeros(N,1);
R = [alpha_a 0; 0 alpha_b];

% pre-computations. This is essentially the eigenvalue & eigenvector 
% calculation of expmdemo3. 'edit expmdemo3' for details
[V0,D0] = eig(L1);
expm_L1TD = V0 * diag(exp(diag(D0)*td)) / V0;

M1 = Mo-R*(Mo-expm_L1TD*Mo);

for kt = 1:N
   expm_L1t = V0 * diag(exp(diag(D0)*ti(kt))) / V0;
   Z = Mo-expm_L1t*M1;
   Mz(kt) = abs(Z(1));
end
