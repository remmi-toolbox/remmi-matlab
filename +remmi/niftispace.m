classdef niftispace < dynamicprops
    % niftispace reads/writes niftifiles in a directory.
    %
    % Example:
    %
    % ns = niftispace(); % use pwd as the current folder path
    % ns = niftispace('/path/to/folder/');
    % 
    % any .nii files with valid filenames in the folder will be accessible
    % via class property as a niftifile object
    %
    % To create a new niftifile 'arbitrary_name.nii':
    % ns.arbitrary_name = test; 
    %
    % where test is any struct like object that contains: 
    % test.img = numeric image data
    % any other data stored in test is converted to json in niftifile and
    % stored in an extension header
    %
    % by Kevin Harkins (kevin.harkins@vanderbilt.edu)
    
    properties
        folderpath % the name used to store the data 
    end
    
    methods
        function obj = niftispace(fpath)
            % niftispace(fpath), constructor
            %   fpath = an optional folder path
            
            if ~exist('fpath','var')
                fpath = pwd;
            end
            
            if ~exist(fpath,'dir')
                error('fpath must exist')
            end
            
            obj.folderpath = fpath;
            
            files = dir(fullfile(obj.folderpath,'*.nii'));
            
            for n=1:length(files)
                fname = fullfile(files(n).folder,files(n).name);
                [~,name,~] = fileparts(fname);
                try
                    nfile = remmi.niftifile(fname);
                    
                    name = strrep(name,'.','_');
                    name = strrep(name,'(','');
                    name = strrep(name,')','');
                    
                    obj.addprop(name);
                    obj.(name) = nfile;
                catch
                    warning('%s could not be loaded',fname);
                end
                
            end
        end
        
        function obj = subsasgn(obj,a,val)
            
            if isprop(obj,a(1).subs)
                % this item already exists
                
                if numel(a) == 1
                    if isa(val,'niftifile') || isstruct(val)
                        % assign niftifile object directly
                        obj.(a(1).subs) = val;
                    else
                        error('value cannot be assigned');
                    end
                else %  numel(a) > 1
                    if strcmp(a(2).type,'.')
                        % carry on
                        obj = builtin('subsasgn',obj,a,val);
                    else
                        error('niftispace properites cannot be arrayed');
                    end
                end
            else
                % we need to create this property. 
                if numel(a) > 1
                    error('assigned structure is not the correct format');
                end
                
                % val should be a struct like object, containing the field
                % img
                try
                    val.img;
                catch
                    error('img property required');
                end
                
                if ~isvarname(a(1).subs)
                    error('property should be a valid variable name');
                end
                
                fname = fullfile(obj.folderpath,[a(1).subs '.nii']);
                nf = remmi.niftifile(fname,val);
                
                % create and assign the property
                obj.addprop(a(1).subs);
                obj.(a(1).subs) = nf;
            end
        end
    end
end