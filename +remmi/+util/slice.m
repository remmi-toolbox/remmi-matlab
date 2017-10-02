function out = slice(in,dim,i,name)
% out = slice(in,dim,i) dyanmic slicing of input matrix  
%
%   slice(in,dim,i)
%       in = input matrix, or structure
%       dim = dimension to be sliced
%       i = range in dim to be included in the output
%       
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

if isstruct(in)
    if ischar(dim)
        dim = {dim};
    end

    if iscell(dim)
        dim = find(ismember(in.labels,dim));
    end
    
    if ~exist('name','var') || isempty(name)
        name = 'img';
    end
    
    data = in.(name);
else
    data = in;
end

% set up dynamic indexing
idx = cell(1, ndims(data));
idx(:) = {':'};
idx(dim) = {i};

data = data(idx{:});

if isstruct(in)
    out = in;
    catidx = 1:ndims(data);
    out.(name) = permute(data,[catidx(catidx~=dim) catidx(catidx==dim)]);
    out.labels = out.labels(catidx(catidx~=dim));
    out.imgsize = size(out.(name));
else
    out = data;
end