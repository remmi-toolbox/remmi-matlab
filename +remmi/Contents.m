%
% MAIN FUNCTIONS:
%
% General and Data Storage
%   remmi.dataset - a generalized container for automatic saving any kind of data  
%   remmi.recon - loads raw data and reconstructs images from recognized 
%       vendor formats
%   remmi.version - returns the current version number
%
% Multiple Spin Echo
%   remmi.mse.MERA - MERA toolbox
%   remmi.mse.mT2 - processes multi-exponential T2 in MERA
%   remmi.mse.analysis - processes generalized relaxation with MERA
%
% Diffusion
%   remmi.dwi.dti - processes DTI
%
% Inversion Recovery
%   remmi.ir.qmt - processes quantitative magnetization transfer
%   remmi.ir.T1 - processes T1 
%
% Utilities
%   remmi.util.apodize - 1d, 2d or 3d tukey apodization
%   remmi.util.slice - slice through multi-dimensional data
%   remmi.util.snrCalc - calculate SNR in a 2D image
%   remmi.util.thresholdmask - create a mask based upon % image intensity
%
% Region of Interest
%   remmi.roi.draw - basic ROI processing of a dataset
%   remmi.roi.copy - copies and applies ROIs from one dataset into another
%
% Vendors
%   remmi.vendors.BrukerPV - class for loading Bruker data
%   remmi.vendors.loadBruker - function to load and order raw Bruker data
%   remmi.vendors.parsBruker - function to load a Bruker parameter file
%   remmi.vendors.bmatBruker - calculates the b-matrix for remmiRARE
%       sequence
%
%   remmi.vendors.Varian - WIP class for loading Varian data
%   remmi.vendors.loadVarian - WIP. loads and orders Varian raw data
%   remmi.vendors.parsVarian - Loads a Varian parameter file
%
%
% HELPER FUNCTIONS:
%
%   remmi.dwi.addbmatrix - adds a b-matrix to a structure
%   remmi.dwi.dtilin - simple linear tensor fitting
%   remmi.dwi.dtinonlin - nonlinear tensor fitting (slow!!!)
%   remmi.ir.ir - signal equation for longitudinal relaxation
%   remmi.ir.sir - Solves bloch equations for 2 compartment selective
%       inversion recovery
%   remmi.mse.calcGeometricMean - returns a function handle to calculate
%       the geometric mean on a spectrum output by MERA
%   remmi.mse.calcT2frac - returns a function handle to calculate a signal
%       fraction between lower & upper T2 bounds from a spectrum output by
%       MERA
%   remmi.mse.mT2options - default options for mT2 processing
%   remmi.recon.ft - basic fourier transform reconstruction
%   remmi.recon.options - default options for fourier transform
%       reconstruction
%   remmi.util.githash - returns the git hash of the current version of
%       REMMI-Matlab
%   remmi.util.strsplit - clone of matlab's 'strsplit' to improve backwards
%       compatibility
%
