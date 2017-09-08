classdef Dataset < handle
    properties
        filename
        set
    end
    
    methods
        function obj = Dataset(name,set)
            if exist('name','var')
                obj.filename = name;
                if exist('set','var')
                    obj.set = set;
                else
                    obj.set = '/';
                end
            else
                obj.filename = 'remmi.h5';
                obj.set = '/';
            end
        end
        
        function B = subsref(obj,S) % note: need to make this recursive for structures
            try
                if isprop(obj,S.subs)
                    B = obj.(S.subs);
                else
                    B = h5read(fullfile(pwd,obj.filename),['/' S.subs]);
                end
            catch
                error(['Dataset ' S.subs ' does not exist']);
            end
        end
        
        function B = subsasgn(obj,S,B) % note: need to make this recursive for structures
            i = h5info(fullfile(pwd,obj.filename),obj.set);
            if ~ismember(S.subs,{i.Datasets.Name})
                h5create(fullfile(pwd,obj.filename),['/' S.subs],size(B));
            end
            h5write(fullfile(pwd,obj.filename),['/' S.subs],B);
            B = obj;
        end
        
    end
end