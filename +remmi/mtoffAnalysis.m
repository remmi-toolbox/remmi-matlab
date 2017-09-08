function mtoffSet = mtoffAnalysis(dset, method,lineshape)
%{ 
function mtoffSet = mtoffAnalysis(dset) performs MT offset saturation 
analysis on the dataset

inputs:
           dset.img - 2D or 3D image data in the format:
                     (x, y, z(optional), offsets, flip_angles)
           dset.mask - optional mask for processing data 
           dset.pars - set of all necessary parameters fo data analysis
           
           method_name - chosen method for performing off res MT analysis 
                         shaped pulse. Choose between:
                         'sled_cw' - Sled and Pike continious wave model                                         
                                   (Sled JG, Pike GB. 2001. Magn Reson Med)
                         'sled_rp' - Sled and Pike rectangular pulse model                                       
                                (   Sled JG, Pike GB. 2001. Magn Reson Med)
                         'ramani' - Ramani model
                                (Ramani A, et al. 2002. Magn Reson Imaging)
                                    (Yarnykh VL, Yuan C. 2004. Neuroimage)   
                         'yarnykh' - Yarnykh and Yuan rectangular pulse 
                                (Yarnykh VL, Yuan C. 2004. Neuroimage)
                         By default it's 'ramani'
           Depending on method_name, two following parameters are set up:

           omega1_method_name - chosen method for approximation of MT 
                                shaped pulse. Currently available:  
                       = @compute_omega1_cw - Sled and Pike continious wave                                         
                       = @compute_omega1_rp - Sled and Pike rectangular pulse                                        
                       = @compute_omega1_rms - Yarnykh and Yuan rectangular pulse 
          

            Mz_method - function handle for function calculating Mz value 
                        for different MT pulse approximations.
                        Currently available: 
                  @SPGR_cw - Sled and Pike continious wave solution 
                  (Sled JG, Pike GB. 2001. Magn Reson Med 46:923-931)

                  @SPGR_rp - Sled and Pike rectangular pulse solution
                  (Sled JG, Pike GB. 2001. Magn Reson Med 46:923-931)

                  @SPGR_ramani - Ramani solution for MT off-res saturation
                  (Ramani A, et al. 2002. Magn Reson Imaging 20:721-731)
                  
                  @SPGR_yarnykh - Yarnykh solution for MT off-res saturation
                  (Yarnykh VL, Yuan C. 2004. Neuroimage)
                        
    lineshape - function handle for function calculating lineshape of
                macromolecular pool. 
                currently available:
                  @gaussian - for gaussian lineshape
                  @lorentzian - for lorentzian lineshape
                  @superlorentzian - for superlorentzian lineshape
                  @superlorentzian_res - for superlorentzian lineshape with
                                         spline of values for offsets less
                                         than 1.5 kHz.
outputs:   mtoffSet - a data set containing main MT offset saturation 
                      parameter maps of: 
           mtoffSet.kfm - exchange rate free-to-macromolecular pool,[s-1]
           mtoffSet.kmf - exchange rate macromolecular-to-free pool,[s-1]
           mtoffSet.R1f - relaxation rate of free pool, [s-1]
           mtoffSet.PSR - pool-size ratio
           mtoffSet.T2m - relaxation time of macromolecular pool, [s-1]
           mtoffSet.T2f - relaxation time of free pool, [s-1]
%}

% size of the dataset
sz = size(dset.img); 

% what dimension is offset & flip angle encoding?
mtDim = ismember(dset.labels,{'MT','EXP'});

if sum(mtDim) ~= 2
    error('Data set does not contain offset mt preps required for fitting');
end

% create a mask, if non is given
if isfield(dset,'mask')
    mask = dset.mask;
else
    mask = true(prod(sz(~mtDim),1));
end

% load in the needed parameters
offsets = dset.pars.mt_offset'; % offset freq in [Hz]

% build pulse data structure
pulse = build_pulse(dset.pars);

% calculate mean saturation rate of macromolecular pool
G = lineshape(offsets, T2m);
omega1_aver = omega1_method(pulse);
W = G .* pi .* omega1_aver.^2;

% load B0 map

% load B1 map

% load T1 map in [s]
T1_map = t1.T1/1000;

% compute Sf
disp('Precomputing...')
T2r = linspace(0.01,0.2,10);
Sf = zeros([length(T2r) length(offsets) length(pulse.amp)]);
for n=1:length(T2r)
    Sf(n,:,:) = remmi.util.mt.compute_Sf(imgset.pars.mt_offset,T2r(n),pulse);
end

Sfun = @(x) squeeze(interp1(T2r,Sf,x,'linear','extrap'));
disp('Done!')

% which method are we fitting?
% for starters, the Sled & Pike continuous wave approximation is default
mtFun = @(x) remmi.util.mt.sledcw(x,W,offsets,dset.pars.mt_power,Sfun);
if exist('method','var');
    if strcmp(method, 'ramani')
        % ramani's method
        mtFun = @(x) remmi.util.mt.ramani(x,W,offsets,dset.pars.mt_power); 
    elseif strcmp(method, 'sled_rp')
        % rectangular pulse approximation
        mtFun = @(x) remmi.util.mt.rp;
    elseif strcmp(method, 'yarnykh')
        % method by Yarnykh et al.
        mtFun = @(x) remmi.util.mt.yarnykh;
    end
end

%     Mz_method = @SPGR_cw;
%     omega1_method = @compute_omega1_cw;
% elseif strcmp(method, 'sled_rp')
%     Mz_method = @SPGR_rp;
%     omega1_method = @compute_omega1_rp;
% elseif strcmp(method, 'ramani')
%     Mz_method = @SPGR_ramani;
%     omega1_method = @compute_omega1_cw;
% elseif strcmp(method, 'yarnykh')
%     Mz_method = @SPGR_yarnykh;
%     omega1_method = @compute_omega1_rms;
% end

% make the mt dimensions the first & second index. 
idx = 1:numel(size(dset.img));
data = permute(dset.img,[idx(mtDim) idx(~mtDim)]);

% initialize the mtoff dataset
mtoffSet.kfm = zeros(sz(~dwDim));
mtoffSet.kmf = zeros(sz(~dwDim));
mtoffSet.PSR = zeros(sz(~dwDim));
mtoffSet.BPF = zeros(sz(~dwDim));
mtoffSet.R1f = zeros(sz(~dwDim));
mtoffSet.T2m = zeros(sz(~dwDim));
mtoffSet.T2f = zeros(sz(~dwDim));

tot_evals = sum(mask(:));
evals = 0;

fprintf('%3.0f %% done...',0);
for n=1:numel(mask)
    if mask(n)

        sig = squeeze(abs(dset.img(:,:,n)));
        % normalize signal for every power. KDH: meh. really?
        sig = sig./max(sig,[],1); 

        [mtoffSet.PSR(n),mtoffSet.kfm(n)] = mtFun(sig);

        evals = evals+1;
    end
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
end
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);



