classdef workspace < dynamicprops
    % remmi.workspace is a general container for any kind of data, especially  
    % given or returned from a remmi process. This class can effectively be
    % used the same way as a matlab structure, except the data is
    % simultaneously stored in the filename given to the constructor. This
    % class should be more efficient than matfile, as the data is also
    % stored in memory.
    %
    % Example:
    % rws = remmi.workspace('test.mat');
    % rws.noise = randn(100);
    %
    % A structure can also be passed to remmi.workspace to preload fields
    % into the workspace. Example:
    % info.spath = '/data/studyname/';
    % info.exps = 10; 
    % rws = remmi.workspace('test.mat',info);
    %
    % Kevin Harkins & Mark Does, Vanderbilt University
    % for the REMMI Toolbox
    
    properties
        filename % the name used to store the data 
    end
    
    methods
        function obj = workspace(fname,initdata)
            % workspace(name), contructor
            %   name = a required alphanumeric string, where the first 
            %   character must be a letter. 
            
            % "name" must be a string with an alpha first character
            if exist(fname,'var') || isempty(fname)
                error('workspace() requires a filename');
            elseif ischar(fname)
                if ~isstrprop(fname(1),'alpha')
                    error('The first character of "name" must be a letter');
                else
                    obj.filename = fname;
                end
            else
                error('"fname" must be a character string');
            end
            
            [p,n,ext] = fileparts(obj.filename);
            if isempty(p)
                obj.filename = fullfile(pwd,[n ext]);
            end
            
            % does this file exist? If so, pre-load it
            if exist(obj.filename,'file')
                % load the current properties
                data = load(obj.filename);
                fields = fieldnames(data);
                
                for n=1:length(fields)
                    p = obj.addprop(fields{n});
                    obj.(fields{n}) = data.(fields{n});
                    p.SetMethod = remmi.workspace.createSetMethod(fields{n});
                end
            end
            
            % was a structure given to initialize the workspace?
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
            p.SetMethod = remmi.workspace.createSetMethod(name);
            
            if exist('data','var')
                obj.(name) = data;
            end
        end
        
        function obj = subsasgn(obj,a,val)
            if isprop(obj,a(1).subs)
                obj = builtin('subsasgn',obj,a,val);
            else
                % we need to create this property. 
                % first recreate val if a is further subreferenced
                if numel(a) > 1
                    if ~strcmp(a(1).type,'.')
                        error('the class remmi.workspace cannot be subreferenced')
                    end
                    
                    if strcmp(a(2).type, '.')
                        str = struct();
                    elseif strcmp(a(2).type,'()')
                        str = [];
                    elseif strcmp(a(2).type,'{}')
                        str = {};
                    end
                    val = subsasgn(str,a(2:end),val);
                end
                
                % create and assign the property
                obj.add(a(1).subs,val);
            end
        end
        
        function a = saveobj(obj)
            % be smart about saving a remmi.workspace to file...
            a.filename = obj.filename;
        end
    end
    
    methods (Static)
        function obj = loadobj(a)
            % be smart about loading a remmi.workspace from file...
            obj = remmi.workspace(a.filename);
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
                    ver = remmi.util.strsplit(version(),{'.' ' '});
                    ver = str2double([ver{1} '.' ver{2}]);
                    if ver < 7.3 % earlier than R2006a
                        save(obj.filename,'-struct','tmp')
                    else % R2006a or later
                        save(obj.filename,'-struct','tmp');%,'-v7.3')
                    end
                end
                
                [~,id] = lastwarn();
                lastwarn(''); % clear other warnings
                if strcmp(id,'MATLAB:save:sizeTooBigForMATFile')
                    warning(['The property ''' name ''' was not saved to file: ' obj.filename]);
                    [p,n,ext] = fileparts(obj.filename);
                    fn = fullfile(p,[n '.' name ext]);
                    save(fn,'-struct','tmp','-v7.3')
                    [~,id] = lastwarn;
                    if isempty(id)
                        disp(['No data has been lost: ''' name ''' was instead saved to ' fn])
                    else
                        warning(['Something is wrong: ''' name ''' could not be saved.'])
                    end
                end
                
            end
        end
    end
end
