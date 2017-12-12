function ws = dataset(varargin)

warning(['remmi.dataset has been renamed to remmi.workspace, ' ...
         'and will be depreciated in later version. Please update ' ...
         'your code to use remmi.workspace()']);

ws = remmi.workspace(varargin{:});