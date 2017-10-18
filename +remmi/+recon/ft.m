function img = ft(data,options)
% img = ft(data,options) performs a basic 2d or 3d fourier transform on
% data. Default options are set in remmi.recon.options();
%
% by Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox


encmatrix = size(data);

if numel(encmatrix) > 3
    encmatrix(3) = 1;
end

% what spatial encoding are we using?
reconmatrix = options.matrix_sz;
if isempty(reconmatrix)
    reconmatrix = encmatrix(1:3);
elseif numel(reconmatrix) ==1
    reconmatrix(1:3) = reconmatrix;
end

% reconstruct images
dat = options.apodize_fn(data);
dat = pad(dat,reconmatrix);
dat = fftshift(fftshift(fftshift(dat,1),2),3);
img = fft(fft(dat,reconmatrix(1),1),reconmatrix(2),2);
if encmatrix(3) > 1
    img = fft(img,reconmatrix(3),3);
end
img = fftshift(fftshift(fftshift(img,1),2),3);

end

function dat = pad(dat,sz)
% add zeros or remove data points so that dat is the size sz

for n=1:length(sz)
    dsz = size(dat);
    if dsz(n) < sz(n)
        % add zeros onto both sides
        dim = dsz;
        dim(n) = (sz(n)-dsz(n))/2;
        dat = cat(n,zeros(ceil(dim)),dat,zeros(floor(dim)));
    elseif dsz(n) > sz(n)
        % trim data from both sides. # of values to trim from both sides
        ntrim = (dsz(n) - sz(n))/2;
        
        %Set up dynamic indexing
        idx = cell(1, ndims(dat));
        idx(:) = {':'};
        idx(n) = {ceil(ntrim)+1:dsz(n)-floor(ntrim)};
        
        dat = dat(idx{:});
    end % else dsz(n) == sz(n). do nothing
end

end