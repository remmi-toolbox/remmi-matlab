function Mz = ir(x,ti,tr)
% function Mz = ir(x,ti,tr) signal equation for longitudinal magnetization
% after an inversion pulse
%   x(1) = magnitude of the free water pool 
%   x(2) = T1 of free water (same units as ti,tr)
%   x(3) = estimated flip angle of the inversion pulse. Range is 0-180
%   degrees
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

Mz = x(1) * (1 - (1-cosd(x(3))) .* exp(-ti/x(2)) + exp(-tr/x(2)));
