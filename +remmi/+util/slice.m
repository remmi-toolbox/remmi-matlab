function out = slice(in,dim,i)
% out = slice(in,dim,i) dyanmic slicing of input matrix  
%
%   slice(in,dim,i)
%       in = input matrix
%       dim = dimension to be sliced
%       i = range in dim to be included in the output
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

% set up dynamic indexing
idx = cell(1, ndims(in));
idx(:) = {':'};
idx(dim) = {i};

out = in(idx{:});