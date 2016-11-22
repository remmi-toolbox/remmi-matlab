function [RE,IM,NP,NB,NT,HDR] = loadVarian(name,blocks,traces)
%----------------------------------------
%function load_fid
%Reads a Vnmr fid file
%----------------------------------------
%Usage [RE,IM,np,nb,HDR] = load_fid(name,blocks,traces);
%
%Input:
%name   = name of FID directory without the .fid extension
%blocks = MATLAB vector of blocks to read; optional, default all
%traces = MATLAB vector of traces to read; optional, default all
%
%Output:
%RE  = real part of data, blocks are ordered columnwise
%IM  = imaginary part
%np  = number of points (rows in RE/IM); optional
%nb  = number of blocks (columns); optional
%nt  = number of traces; optional
%HDR = data header + last block header; optional
%
%Examples:
%[RE IM] = load_fid('Test_data');
%[RE IM np nb] = load_fid('Test_data');
%
%----------------------------------------
% Maj Hedehus, Varian, Inc., Sep 2001.
%----------------------------------------
 
% format input name
if ispc,
    slash = '\';
else
    slash = '/';
end
    

fullname = sprintf('%s.fid%cfid',name,slash); 
 
fid = fopen(fullname,'r','ieee-be');
if fid == -1
   str = sprintf('Can not open file %s',fullname);
  error(str);
end
 
% Read datafileheader
nblocks   = fread(fid,1,'int32');
ntraces   = fread(fid,1,'int32');
np        = fread(fid,1,'int32');
ebytes    = fread(fid,1,'int32');
tbytes    = fread(fid,1,'int32');
bbytes    = fread(fid,1,'int32');
vers_id   = fread(fid,1,'int16');
status    = fread(fid,1,'int16');
nbheaders = fread(fid,1,'int32');
 
 
s_data    = bitget(status,1);
s_spec    = bitget(status,2);
s_32      = bitget(status,3);
s_float   = bitget(status,4);
s_complex = bitget(status,5);
s_hyper   = bitget(status,6);
 
%removed to prevent dynamic reallocation of resources
% reset output structures
%RE = [];
%IM = [];
 
%if exist('blocks')==0
    blocks = 1:nblocks;
%end
outblocks = max(size(blocks));
 
if exist('traces') == 0
    traces = 1:ntraces;
end
outtraces = max(size(traces));

%added to prevent dynamic reallocation of resources
RE=zeros(np/2, ntraces*nblocks);
IM=zeros(np/2, ntraces*nblocks);
 
 
inx = 1;
B = 1;
for b = 1:nblocks
    sprintf('read block %d\n',b);
    % Read a block header
    scale     = fread(fid,1,'int16');
    bstatus   = fread(fid,1,'int16');
    index     = fread(fid,1,'int16');
    mode      = fread(fid,1,'int16');
    ctcount   = fread(fid,1,'int32');
    lpval     = fread(fid,1,'float32');
    rpval     = fread(fid,1,'float32');
    lvl       = fread(fid,1,'float32');
    tlt       = fread(fid,1,'float32');
    
    T = 1;
    update_B = 0;
    for t = 1:ntraces
        %We have to read data every time in order to increment file pointer
        if s_float == 1
            data = fread(fid,np,'float32');
            str='reading floats';
        elseif s_32 == 1
            data = fread(fid,np,'int32');
            str='reading 32bit';
        else
            data = fread(fid,np,'int16');
            str='reading 16bit';
        end
        
        % keep data if this block & trace was in output list
        if (blocks(B) == b)
            if T <= outtraces
                if (traces(T) == t)
                    sprintf('Reading block %d, trace %d, inx = %d\n',b,T,inx);
                    RE(:,inx) = data(1:2:np);
                    IM(:,inx) = data(2:2:np);
                    inx = inx + 1;
                    T = T + 1;
                    update_B = 1;
                end %keep this trace
            end %still within limit of outtraces
        end %keep this block
    end %trace loop
    
    if update_B, B = B + 1; end
    
    if B > outblocks
        break
    end
end  % done reading one block
 
 
if nargout > 2
    NP = np/2;
end
if nargout > 3
    NB = nblocks;
end
if nargout > 4
    NT = ntraces;
end
if nargout > 5
    HDR = [nblocks, ntraces, np, ebytes, tbytes, bbytes, vers_id, status, nbheaders];
    HDR = [HDR, scale, bstatus, index, mode, ctcount, lpval, rpval, lvl, tlt];
end
fclose(fid);
