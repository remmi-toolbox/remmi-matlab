function [adc,fa,vec,eign] = dtilin(sig,bmat)

sig1 = -log(sig/sig(1));

D = (bmat*bmat')\(bmat*sig1);
D = diag(D(1:3)) + diag(D(4:5),-1) + diag(D(4:5),1) + diag(D(6),-2) + diag(D(6),2);

[vec,val] = eig(D);
eign = diag(val)*1000;

adc = mean(eign);
fa = sqrt(3/2*sum((eign-adc).^2)/sum(eign.^2));