function procpar = parsVarian(pathname)
%parsePP: Returns the contents of a Varian procpar file in a structure
%
%Usage: procpar = parsePP(experimentName);
%         
%NOTES: Float parameters are converted from strings with str2num.  This
%          function will cast the values to double precision.  The
%          function str2double will only accept a single value, which is
%          incompatible with some parameter entries, so str2num is used
%          throughout for consistency.
%       This file was derived from queryPP, written by Maj Hedehus.
%          Although this function bears little resemblance to queryPP,
%          the control structure was taken directly from it, and as such,
%          Maj gets top billing.
%----------------------------------------
% Maj Hedehus, Varian, Inc., Oct 2001.
% modified by J. Luci for more general use.
%----------------------------------------



%fullname = [pathname, '\procpar'];
fullname=pathname;
fid = fopen(fullname,'r');
if fid == -1
    str = sprintf('Can not open file %s',fullname);
    error(str);
end

while ~feof(fid)
    par  = fscanf(fid,'%s',1);
    type  = fscanf(fid,'%d',1);
        if strcmp(par,'com$string')
       type=8;
        end
    fgetl(fid); %skip rest of line
    nvals = fscanf(fid,'%d',1);

    switch type
        case 1  % float
            eval(['procpar.' par '= fscanf(fid,''%f'',nvals);']);
            skip=fgetl(fid);
            skip=fgetl(fid);
        case 2  % string
            fullstr=[];
            for ii = 1:nvals,
                str = uint8(fgetl(fid));
                if str(1) == 32, 
                    str=str(2:end);  %strip off leading space if it exists
                end
                str = str(2:size(str,2)-1); %strip off double quotes from the string
                fullstr = [fullstr str 10]; %10 is the ASCII code for LF
            end
            fullstr=char(fullstr);
            eval(['procpar.' par '= fullstr;']);
            skip=fgetl(fid);
        case 3  % delay
            eval(['procpar.' par '= fscanf(fid,''%f'',nvals);']);
            skip=fgetl(fid);
            skip=fgetl(fid);
        case 4  % flag
            L = uint8(fgetl(fid));
            if L(1) == 32, 
                L=L(2:end); %strip off leading space if it exists
            end 
            L = L(2:size(L,2)-1);  %strip off double quotes from the string
            L=char(L);
            eval(['procpar.' par '= L;']);
            skip=fgetl(fid);
        case 5  % frequency      
            eval(['procpar.' par '= fscanf(fid,''%f'',nvals);']);
            skip=fgetl(fid);
            skip=fgetl(fid);
        case 6  % pulse
            L = str2double(fgetl(fid));
            eval(['procpar.' par '= L;']);
            skip=fgetl(fid);
        case 7  % integer
            num = str2num(fgetl(fid));
            eval(['procpar.' par '= num;']);
            skip=fgetl(fid);
        case 8
           fgetl(fid);
           fgetl(fid);
    end
end
fclose(fid);