function pars = parsBruker(filename)
% pars = parsBruker(filename)
%   filename = any parameter file from Bruker scan
%   pars: list of all parameters & their values contained within the file
%
% Kevin Harkins & Mark Does, Vanderbilt University
% for the REMMI Toolbox

fid = fopen(filename,'r');
if fid == -1
    error('Could not open method file: %s',filename);
end % if


line = fgetl(fid); % read the first line
while line ~= -1
    if strcmp(line(1:min(end,3)),'##$')
        % this line describes a parameter
        line = line(4:end);
        idx = strfind(line,'=');
        if length(idx) ~= 1
            warning('Unable to parse line: %s',line);
        end
        
        parID = line(1:idx-1);
        value = line(idx+1:end);
        
        if strcmp(value(1),'(')
            % This is an array of values. How many values should be in this array?
            nval = str2num(value(2:end-1));
            if isempty(nval)
                % Read the whole thing in, and save as a string
                all_lines = value;
                this_line = strtrim(fgetl(fid));
                
                while ~strcmp(this_line(1),'#') && ~strcmp(this_line(1),'$')
                    all_lines = [all_lines ' ' this_line];
                    this_line = strtrim(fgetl(fid));
                    pars.(parID) = all_lines;
                end
                
                line = this_line;
                continue;
            end
            
            all_lines = '';
            this_line = strtrim(fgetl(fid));
            while ~strcmp(this_line(1),'#') && ~strcmp(this_line(1),'$')
                all_lines = [all_lines ' ' this_line];
                this_line = strtrim(fgetl(fid));
            end
            
            % read the array of values
            all_lines = strtrim(all_lines);
            [val, status] = str2num(all_lines);
            if status % read as a number
                pars.(parID) = val;
            elseif isempty(all_lines)
                pars.(parID) = nval;
            else % read as a string
                if strcmp(all_lines(1),'<') && strcmp(all_lines(end),'>')
                    % remove brackets 
                    all_lines = all_lines(2:end-1);
                end
                
                pars.(parID) = all_lines;
            end
            
            line = this_line;
        else
            % read a single value
            [val, status] = str2num(value);
            if status
                % read as a number
                pars.(parID) = val;
            else
                % read as a string
                pars.(parID) = value;
            end
            
            line = fgetl(fid); % read the whole line
        end % if
    else
        line = fgetl(fid); % read the whole line
    end
end
fclose(fid);


