function mtirSet = mtirAnalysis(dset)
% mtirSet = mtirAnalysis(dset) performs MTIR analysis on the dataset: 
%
%   mtirAnalysis(dset)
%       dset.img = image data in the format (x,y,z,ti) (constant td)
%       dset.mask = mask for processing data (optional, but speeds up
%           computation time)
%       dset.pars = basic remmi parameter set including ti & td. 
% 
%   Returns a data set containing mtir parameter maps of M0a, M0b, BPF, PSR, 
%   kmf, T1 & confidence interavls.
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% load in the dataset
sz = size(dset.img); 

% load in the needed parameters
ti = dset.pars.ti/1000;
td = dset.pars.td/1000;

% define a mask if one is not given
if isfield(dset,'mask')
    mask = dset.mask;
else
    mask = true(prod(sz(1:3),1));
end

% initialize the mtir dataset
mtirSet.M0a = zeros(size(mask));
mtirSet.M0b = zeros(size(mask));
mtirSet.PSR = zeros(size(mask));
mtirSet.BPF = zeros(size(mask));
mtirSet.kmf = zeros(size(mask));
mtirSet.T1 = zeros(size(mask));
mtirSet.ci = cell(size(mask));

lb = [0 0 0 0 -1];
ub = [inf inf inf inf 1];

tot_evals = sum(mask(:));
evals = 0;

warning('off','MATLAB:singularMatrix')

fprintf('%3.0f %% done...',0);
for ro=1:size(dset.img,1)
    for pe=1:size(dset.img,2)
        for sl=1:size(dset.img,3)
            if mask(ro,pe,sl)
                
                sig = squeeze(abs(dset.img(ro,pe,sl,:)));

                % initial guess for soft IR, alpha = 0.8
                b0 = [max(sig)/2, max(sig)/3,10,2,-0.9]; 
                
                % fit the data
                opts = optimset('display','off');
                [b,~,res,~,~,~,jac] = lsqnonlin(@(x) remmi.util.sir(x,ti',td)-sig,b0,lb,ub,opts);
                
                % load the dataset
                mtirSet.M0a(ro,pe,sl)=b(1);
                mtirSet.M0b(ro,pe,sl)=b(2);
                mtirSet.PSR(ro,pe,sl)=b(2)/b(1); %M0b/M0a
                mtirSet.BPF(ro,pe,sl)=b(2)/(b(2)+b(1));
                mtirSet.kmf(ro,pe,sl)=b(3);
                mtirSet.T1(ro,pe,sl)=1/b(4);
                
                % save confidence intervals on the original parameters
                mtirSet.ci{ro,pe,sl} = nlparci(b,res,'jacobian',jac); 
                
                evals = evals+1;
            end
        end
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...',evals/tot_evals*100);
    end
end
fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b%3.0f %% done...\n',100);

warning('on','MATLAB:singularMatrix')


