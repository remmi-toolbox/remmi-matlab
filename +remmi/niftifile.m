classdef niftifile < dynamicprops
    % niftifile is a minimalist class container to read/write nifti-1 files
    %
    % Example:
    % nf = niftifile('file.nii');
    % 
    % nf.img = image data in single or double format. real/complex are
    %   supported
    %
    % or:
    % nf = niftifile('file.nii',data);
    % where data is any struct-like matlab oject containting a field 'img' 
    % of numeric image data. All other fields in the structure are
    % converted to json and saved in the nifti extension header
    %
    % by Kevin Harkins (kevin.harkins@vanderbilt.edu)
    
    properties
        filepath % the name used to store the data 
        img = [];
    end
    
    properties (Access = private)
        parscode = 2984; % random integer ?
        dirty = false;
        typecode;
        bitcode;
    end
    
    methods
        function obj = niftifile(fname,data)
            % niftifile(fname,data), constructor
            %   fname = a required alphanumeric string, where the first 
            %   character must be a letter. 
            
            % for now, only floats & doubles (real or complex) are used
            obj.typecode = containers.Map;
            obj.typecode('uint8') = 2;
            obj.typecode('int16') = 4;
            obj.typecode('int32') = 8;
            obj.typecode('single') = 16;
            obj.typecode('single complex') = 32;
            obj.typecode('double') = 64;
            obj.typecode('double complex') = 1792;
            
            obj.bitcode = containers.Map;
            obj.bitcode('uint8') = 8;
            obj.bitcode('int16') = 16;
            obj.bitcode('int32') = 32;
            obj.bitcode('single') = 32;
            obj.bitcode('single complex') = 64;
            obj.bitcode('double') = 64;
            obj.bitcode('double complex') = 128;
            
            if ~exist('fname','var') || isempty(fname)
                error('niftifile() requires a filename');
            elseif ischar(fname)
                obj.filepath = fname;
            else
                error('"fname" must be a character string');
            end
            
            % check to make sure we aren't writing over any saved data
            if exist('fname','file') && exist('data','var')
                error('file %s already exists',fname)
            end
            
            if exist('data','var')
                if isnumeric(data.img)
                    obj.img = data.img;
                else
                    error('img must be numeric')
                end
                
                fns = fieldnames(data);
                for n = 1:length(fns)
                    if strcmp(fns{n},'img')
                        continue;
                    end
                    obj.addprop(fns{n});
                    obj.(fns{n}) = data.(fns{n});
                end

                obj.dirty = true;
                
                obj.write();
            elseif exist(obj.filepath,'file')
                % load the current properties
                obj.readimg();
                obj.readpars();
                obj.dirty = false;
            end
        end
        
        function delete(obj)
            if (obj.dirty)
                obj.write();
            end
        end
        
        function js = jsondynprops(obj)
            props = properties(obj);
            save_struc = struct;
            for n=1:length(props)
                if strcmp(props{n},'filepath') || strcmp(props{n},'img')
                    continue;
                end
                save_struc.(props{n}) = obj.(props{n});
            end
              
            % get size of the header extension 
            js = jsonencode(save_struc);
        end
        
        
        function obj = subsasgn(obj,a,val)
            obj.dirty = true;
            
            % basic type checking
            if numel(a) == 1
                if strcmp(a(1).subs,'img')
                    if isnumeric(val)
                        obj.img = val;
                    else
                        error('img must be numeric')
                    end
                elseif ~isprop(obj,a(1).subs)
                    % we need to create this property
                    obj.addprop(a(1).subs);
                    obj.(a(1).subs) = val;
                else
                    % carry on
                    obj = builtin('subsasgn',obj,a,val);
                end
            else
                % carry on
                obj = builtin('subsasgn',obj,a,val);
            end
            
            obj.write();
        end

        function hdr = generateHeader(obj)
            hdr = struct();
            
            hdr.sizeof_hdr = int32(348);
            
            % unused by nifti-1
            hdr.data_type = char(zeros(10,1));
            hdr.db_name = char(zeros(18,1));
            hdr.extents = int32(0);
            hdr.session_error = int16(0);
            hdr.regular = char(0);
            
            % 
            sz = size(obj.img);
            if length(sz)>7
                error('image data must have 7 or less dimensions')
            end
            sz = [length(sz) sz];
            sz(length(sz)+1:8) = 1; % pad to 8 values
            hdr.dim_info = char(0);
            hdr.dim = int16(sz);
            hdr.intent_p1 = single(0);
            hdr.intent_p2 = single(0);
            hdr.intent_p3 = single(0);
            hdr.intent_code = int16(0);
            
            cl = class(obj.img);
            if ~isreal(obj.img)
               cl = strcat(cl,' complex');
            end
            
            if ~any(strcmp(keys(obj.bitcode),cl))
                error('data type is not recognized')
            end
            
            hdr.datatype = int16(obj.typecode(cl));
            hdr.bitpix = int16(obj.bitcode(cl));
            hdr.slice_start = int16(0);
            
            hdr.pixdim = single([1 1 1 1 1 1 1 1]);
            js = jsondynprops(obj);
            if ~isempty(js)
                hdre_sz = length(js) + 8;
                hdre_sz = ceil(hdre_sz/16)*16; % must be a multiple of 16
            else
                hdre_sz = 0;
            end
            hdr.vox_offset = 352 + hdre_sz;
            
            hdr.scl_slope = single(0);
            hdr.scl_inter = single(0);
            hdr.slice_end = int16(0);
            hdr.slice_code = char(0);
            hdr.xyzt_units = char(2+16);
            hdr.cal_max = single(0);
            hdr.cal_min = single(0);
            hdr.slice_duration = single(0);
            hdr.toffset	 = single(0);
            hdr.glmax = int32(0);
            hdr.glmin = int32(0);
            hdr.descrip = char(zeros(1,80));
            hdr.aux_file = char(zeros(1,24));
            hdr.qform_code = int16(0);
            hdr.sform_code = int16(0);
            hdr.quatern_b = single(0);
            hdr.quatern_c = single(0);
            hdr.quatern_d = single(0);
            hdr.qoffset_x = single(0);
            hdr.qoffset_y = single(0);
            hdr.qoffset_z = single(0);
            hdr.srow_x = single(zeros(4,1));
            hdr.srow_y = single(zeros(4,1));
            hdr.srow_z = single(zeros(4,1));
            hdr.intent_name = char(zeros(1,16));
            hdr.magic = ['n+1' 0];
            hdr.ext = char([1 0 0 0]);
        end

        function write(obj)
            
            hdr = obj.generateHeader();
            
            % open the file
            fid = fopen(obj.filepath,'w','ieee-le');
            
            if fid<0
                error('could not open %s', obj.filepath);
            end
            
            % write the header
            fwrite(fid,hdr.sizeof_hdr,'int32');
            fwrite(fid,hdr.data_type,'char');
            fwrite(fid,hdr.db_name,'char');
            fwrite(fid,hdr.extents,'int32');
            fwrite(fid,hdr.session_error,'int16');
            fwrite(fid,hdr.regular,'char');
            fwrite(fid,hdr.dim_info,'char');
            fwrite(fid,hdr.dim,'int16');
            fwrite(fid,hdr.intent_p1,'single');
            fwrite(fid,hdr.intent_p2,'single');
            fwrite(fid,hdr.intent_p3,'single');
            fwrite(fid,hdr.intent_code,'int16');
            fwrite(fid,hdr.datatype,'int16');
            fwrite(fid,hdr.bitpix,'int16');
            fwrite(fid,hdr.slice_start,'int16');
            fwrite(fid,hdr.pixdim,'single');
            fwrite(fid,hdr.vox_offset,'single');
            fwrite(fid,hdr.scl_slope,'single');
            fwrite(fid,hdr.scl_inter,'single');
            fwrite(fid,hdr.slice_end,'int16');
            fwrite(fid,hdr.slice_code,'char');
            fwrite(fid,hdr.xyzt_units,'char');
            fwrite(fid,hdr.cal_max,'single');
            fwrite(fid,hdr.cal_min,'single');
            fwrite(fid,hdr.slice_duration,'single');
            fwrite(fid,hdr.toffset,'single');
            fwrite(fid,hdr.glmax,'int32');
            fwrite(fid,hdr.glmin,'int32');
            fwrite(fid,hdr.descrip,'char');
            fwrite(fid,hdr.aux_file,'char');
            fwrite(fid,hdr.qform_code,'int16');
            fwrite(fid,hdr.sform_code,'int16');
            fwrite(fid,hdr.quatern_b,'single');
            fwrite(fid,hdr.quatern_c,'single');
            fwrite(fid,hdr.quatern_d,'single');
            fwrite(fid,hdr.qoffset_x,'single');
            fwrite(fid,hdr.qoffset_y,'single');
            fwrite(fid,hdr.qoffset_z,'single');
            fwrite(fid,hdr.srow_x,'single');
            fwrite(fid,hdr.srow_y,'single');
            fwrite(fid,hdr.srow_z,'single');
            fwrite(fid,hdr.intent_name,'char');
            fwrite(fid,hdr.magic,'char');
            
            if ftell(fid) ~= 348
                error('something is wrong')
            end
            
            % write the header exentsion
            
            % get size of the header extension 
            js = jsondynprops(obj);
            extsz = length(js)+8;
            extsz = ceil(extsz/16)*16;
            js(extsz-8) = ' ';
            
            if extsz > 0
                fwrite(fid,char([1 0 0 0]),'char');
                
                fwrite(fid,int32(extsz),'int32');
                fwrite(fid,int32(obj.parscode),'int32');
                fwrite(fid,js,'char');
            else
                fwrite(fid,char([0 0 0 0]),'char');
            end
            
            
            if ftell(fid) ~= hdr.vox_offset
                error('something is wrong v2')
            end
            
            % now, write the data
            if isreal(obj.img)
                fwrite(fid,obj.img,class(obj.img));
            else % data is complex
                r = real(obj.img);
                i = imag(obj.img);
                r = cat(8,r,i);
                r = permute(r,[8 1:7]);
                fwrite(fid,r,class(r));
            end
            
            % close the file
            fclose(fid);
            
            obj.dirty = false;
            
        end
        
        function hdr = readheader(obj)
            % open the file
            fid = fopen(obj.filepath,'r','ieee-le');
            
            if fid<0
                error('could not open %s', obj.filepath);
            end
            
            hdr = struct();
            
            % write the header
            hdr.sizeof_hdr = fread(fid,1,'*int32');
            hdr.data_type = fread(fid,10,'*char')';
            hdr.db_name = fread(fid,18,'*char')';
            hdr.extents = fread(fid,1,'*int32');
            hdr.session_error = fread(fid,1,'*int16');
            hdr.regular = fread(fid,1,'*char')';
            hdr.dim_info = fread(fid,1,'*char')';
            hdr.dim = fread(fid,8,'*int16');
            hdr.intent_p1 = fread(fid,1,'*single');
            hdr.intent_p2 = fread(fid,1,'*single');
            hdr.intent_p3 = fread(fid,1,'*single');
            hdr.intent_code = fread(fid,1,'*int16');
            hdr.datatype = fread(fid,1,'*int16');
            hdr.bitpix = fread(fid,1,'*int16');
            hdr.slice_start = fread(fid,1,'*int16');
            hdr.pixdim = fread(fid,8,'*single');
            hdr.vox_offset = fread(fid,1,'*single');
            hdr.scl_slope = fread(fid,1,'*single');
            hdr.scl_inter = fread(fid,1,'*single');
            hdr.slice_end = fread(fid,1,'*int16');
            hdr.slice_code = fread(fid,1,'*char')';
            hdr.xyzt_units = fread(fid,1,'*char')';
            hdr.cal_max = fread(fid,1,'*single');
            hdr.cal_min = fread(fid,1,'*single');
            hdr.slice_duration = fread(fid,1,'*single');
            hdr.toffset = fread(fid,1,'*single');
            hdr.glmax = fread(fid,1,'*int32');
            hdr.glmin = fread(fid,1,'*int32');
            hdr.descrip = fread(fid,80,'*char')';
            hdr.aux_file = fread(fid,24,'*char')';
            hdr.qform_code = fread(fid,1,'*int16');
            hdr.sform_code = fread(fid,1,'*int16');
            hdr.quatern_b = fread(fid,1,'*single');
            hdr.quatern_c = fread(fid,1,'*single');
            hdr.quatern_d = fread(fid,1,'*single');
            hdr.qoffset_x = fread(fid,1,'*single');
            hdr.qoffset_y = fread(fid,1,'*single');
            hdr.qoffset_z = fread(fid,1,'*single');
            hdr.srow_x = fread(fid,4,'*single');
            hdr.srow_y = fread(fid,4,'*single');
            hdr.srow_z = fread(fid,4,'*single');
            hdr.intent_name = fread(fid,16,'*char')';
            hdr.magic = fread(fid,4,'*char')';
        end
        
        function readpars(obj)
            
            hdr = obj.readheader();
            
            if hdr.vox_offset == 352
                % there are no extensions
                return
            end
            
            fid = fopen(obj.filepath,'r','ieee-le');
            
            if fid<0
                error(['file not found: ' obj.filepath])
            end
            
            f1 = fread(fid,1,'int32');
            if f1 ~= 348
                fclose(fid);
                fid = fopen(obj.filepath,'r','ieee-be');
                f1 = fread(fid,1,'int32');
                
                if f1 ~= 348
                    error(['not a nifti file: ' obj.filepath])
                end
            end
            
            fseek(fid,348,'bof');
            ex_info = fread(fid,4)';
            
            if ex_info(1) == 0
                % there are no extensions
                fclose(fid);
                return;
            end
            
            i = 1;
            while (ftell(fid) < hdr.vox_offset)
                esize = fread(fid,1,'int32');
                ecode = fread(fid,1,'int32');
                edata = char(fread(fid,esize-8)');
                edata = strtrim(edata(edata~=0));
                
                if ecode == obj.parscode
                    istr = jsondecode(edata);
                    f = fieldnames(istr);
                    for n=1:length(f)
                        obj.addprop(f{n});
                        obj.(f{n}) = istr.(f{n});
                    end
                end
                i = i+1;
            end
            fclose(fid);
        end
        
        function readimg(obj)
            
            hdr = obj.readheader();
            
            % what kind of data is this?
            idx = cellfun(@(x) x==hdr.datatype,obj.typecode.values);
            key = obj.typecode.keys;
            str = key{idx};
            cpx = strfind(str,'complex');
            
            mult=1;
            if cpx
                str = str(1:end-8);
                mult=2;
            end
            
            shp = hdr.dim(2:hdr.dim(1)+1);
            
            fid = fopen(obj.filepath,'r','ieee-le');
            if fid<0
                error(['file not found: ' obj.filepath])
            end
            
            fseek(fid,hdr.vox_offset,'bof');
            obj.img = fread(fid,prod(shp)*mult,['*' str]);
            fclose(fid);
            
            if cpx
                obj.img = reshape(obj.img,2,[]);
                obj.img = obj.img(1,:) + 1i*obj.img(2,:);
            end
            
            obj.img = reshape(obj.img,shp');
            
        end
    end
end
