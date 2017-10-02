function snr = snrCalc(img)
% snr = snrCalc(img) estimates SNR on a 2D magntidue image after asking 
% for ROIs in regions in signal and in noise.
%
% by Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% Display image
figure();
imagesc(abs(img));
colormap jet
colorbar
axis image off

% draw signal ROI
title('Draw signal ROI','Fontsize',20);
disp('Draw signal ROI');
sig = roipoly();

% draw noise ROI
disp('Draw noise ROI')
title('Draw noise ROI','Fontsize',20);
noise = roipoly();

snr = mean(abs(img(sig)))/mean(abs(img(noise)))*sqrt(pi/2);

disp(['SNR = ' num2str(snr)]);