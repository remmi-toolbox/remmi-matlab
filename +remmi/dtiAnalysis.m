function dtiSet = dtiAnalysis(dset)
% dtiSet = dtiAnalysis(dset,mode) performs DTI analysis on the dataset: 
%
%   dtiAnalysis(dset)
%       dset.img = image data in the format (x,y,z,:,diff) (constant td)
%       dset.mask = mask for processing data (optional, but speeds up
%           computation time)
%       dset.bmat = condensed bmatrix in ms/µm^2
% 
%   Returns a data set containing dti parameter maps of ADC & FA.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% load in the dataset
sz = size(dset.img); 

bmat = dset.bmat;

if isfield(dset,'mask')
    mask = dset.mask;
else
    mask = true(prod(sz(1:3),1));
end

% for now, we only have the linear model working
diffFun = @(x) remmi.util.dtilin(x,bmat);

% initalize data set to appropriate sizes
dtiSet.fa = zeros(sz(1:4));
dtiSet.adc = zeros(sz(1:4));
dtiSet.vec = zeros([sz(1:4) 3 3]);
dtiSet.eig = zeros([sz(1:4) 3]);

tot_evals = sum(mask(:))*sz(4);
evals = 0;

fprintf('%3.0f %% done...',0);
for nx = 1:sz(1)
    for ny = 1:sz(2)
        for nz = 1:sz(3)
            if mask(nx,ny,nz)
                for ni = 1:sz(4)
                    sig = squeeze(dset.img(nx,ny,nz,ni,:));
                    
                    [adc,fa,vec,eig] = diffFun(sig);
                    
                    dtiSet.fa(nx,ny,nz,ni) = fa;
                    dtiSet.adc(nx,ny,nz,ni) = adc;
                    dtiSet.vec(nx,ny,nz,ni,:,:) = vec;
                    dtiSet.eig(nx,ny,nz,ni,:) = eig;
                    evals = evals+1;
                end
            end
        end
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
    end
end
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);