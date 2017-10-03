classdef dataset < dynamicprops
    % remmi.dataset is a general container for any kind of data, especially  
    % given or returned from a remmi process. This class can effectively be
    % used the same way as a matlab structure, except the data is
    % simultaneously stored in the filename given to the constructor. This
    % class should be more efficient than matfile, as the data is also
    % stored in memory.
    %
    % Example:
    % dset = remmi.dataset('test.mat');
    % dset.noise = randn(100);
    %
    % Kevin Harkins & Mark Does, Vanderbilt University
    % for the REMMI Toolbox
    
    properties
        filename % the name used to store the data 
    end
    
    methods
        function obj = dataset(fname,initdata)
            % dataset(name), contructor
            %   name = a required alphanumeric string, where the first 
            %   character must be a letter. 
            
            % "name" must be a string with an alpha first character
            if exist(fname,'var') || isempty(fname)
                error('dataset() requires a filename');
            elseif ischar(fname)
                if ~isstrprop(fname(1),'alpha')
                    error('The first character of "name" must be a letter');
                else
                    obj.filename = fname;
                end
            else
                error('"fname" must be a character string');
            end
            
            % does this file exist? If so, pre-load it
            if exist(obj.filename,'file')
                % load the current properties
                data = load(obj.filename);
                fields = fieldnames(data);
                
                for n=1:length(fields)
                    p = obj.addprop(fields{n});
                    obj.(fields{n}) = data.(fields{n});
                    p.SetMethod = remmi.dataset.createSetMethod(fields{n});
                end
            end
            
            % was a structure given to initialize the dataset?
            if exist('initdata','var')
                fields = fieldnames(initdata);
                
                for n=1:length(fields)
                    if isprop(obj,fields{n})
                        obj.(fields{n}) = initdata.(fields{n});
                    else
                        obj.add(fields{n},initdata.(fields{n}));
                    end
                end
            end
        end
        
        function add(obj,name,data)
            p = obj.addprop(name);
            p.SetMethod = remmi.dataset.createSetMethod(name);
            
            if exist('data','var')
                obj.(name) = data;
            end
        end
        
        function obj = subsasgn(obj,a,val)
            if isprop(obj,a(1).subs)
                obj = builtin('subsasgn',obj,a,val);
            else
                if numel(a) > 1
                    error(['The field ' a(1).subs ' should be created before it can be sub referenced']);
                end
                
                % create the field
                p = obj.addprop(a.subs);
                p.SetMethod = remmi.dataset.createSetMethod(a.subs);
                obj.(a.subs) = val;
            end
        end
    end
    methods (Static, Access = private)
        function method = createSetMethod(name)
            method = @setmethod;
            
            function setmethod(obj, value)
                obj.(name) = value;
                tmp.(name) = value;
                
                if exist(obj.filename,'file')
                    save(obj.filename,'-struct','tmp','-append')
                else
                    save(obj.filename,'-struct','tmp')
                end
            end
        end
    end
end
