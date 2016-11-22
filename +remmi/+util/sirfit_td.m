function Er = sirfit_td(X,t,Mza,Td,R1b)
% function Er = sirfit(X,t,Mza,Td,R1b);
% by Mark D Does

Moa = X(1); % guess for free water pool
Mob = X(2); % guess for macro pool 
kba = X(3); % exchange macro to water
R1a = X(4); % R1 of free water (measured R1)
alpha_a = X(5); % inv efficiency 
alpha_b = 0.83;

TD = Td;
Mo = [Moa;Mob];
kab = kba*Mob/Moa;
L1 = [-(R1a+kab) kba; kab -(R1b+kba)];

N = length(t);
Mzap = zeros(N,1);
R = [alpha_a 0; 0 alpha_b];

% pre-compute
% Eigenvalue & eigenvector calculation of expm. See expmdemo3. 
[V0,D0] = eig(L1);
expm_L1TD = V0 * diag(exp(diag(D0)*TD)) / V0;

M1 = Mo-R*(Mo-expm_L1TD*Mo);

for kt = 1:N
   expm_L1t = V0 * diag(exp(diag(D0)*t(kt))) / V0;
   Z = Mo-expm_L1t*M1;
   Mzap(kt) = abs(Z(1));
end

Er = (Mza-Mzap);