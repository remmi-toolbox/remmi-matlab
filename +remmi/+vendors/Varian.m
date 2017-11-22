classdef Varian < handle
    % Varian is a class used to identify and reconstruct Varian
    % VNMRJ datasets and images. 
    properties
        path
        labels= {'RO','PE1','PE2','NE','NS','DW','IR','MT','NR'};
    end
    
    methods(Static)
        function bool = isValid(spath)
            bool = exist(fullfile(spath,'study.xml'),'file') == 2;
        end
        
        function time = parsetime(val)
            try
                time = datenum(val,'yyyymmddTHHMMSS');
            catch 
                warning(['Could not parse time: ' val]);
                time = 0;
            end
        end
    end
    
    methods
        function obj = Varian(spath)
            % initiates a study
            
            % ask for a directory if one isn't given
            if exist('spath','var') ~= 1 || isempty(spath)
                obj.path = uigetdir('Pick a study');
            else
                obj.path = spath;
            end
            
            % is this a valid study?
            if ~obj.isValid(spath)
                error('Study is not valid: %s',spath);
            end 
        end
        
        function studies = list(obj)
            % find a list of all the experiments in this study, and sort
            % them by experiment ime
            % 
            % the function returns a structure of study experiment names
            % and ids to identify each experiment.
            exps = dir(obj.path);
            time = zeros(size(exps))-1;
            sid = {exps.name};
            name = cell(size(sid));
            for n=1:length(exps)
                try
                    acqpars = remmi.vendors.parsBruker(fullfile(obj.path,sid{n},'acqp'));
                    time(n) = remmi.vendors.BrukerPV.parsetime(acqpars.ACQ_time);
                    if acqpars.ACQ_sw_version(4) == '5'
                        name{n} = [acqpars.ACQ_scan_name ' (E' sid{n} ')'];
                    else
                        name{n} = acqpars.ACQ_scan_name;
                    end
                catch
                end
            end
            
            % remove experiments that didn't finish
            mask = time>=0;
            sid = sid(mask);
            name = name(mask);
            time = time(mask);
            
            % sort by completion time
            [time,i] = sort(time);
            sid = sid(i);
            name = name(i);
            
            % if experiments have the same name, they are pre-scans. Take
            % the last one 
            [name,idx] = unique(name,'last');
            sid = sid(idx);
            time = time(idx);
            
            % the order was sorted by 'unique'. Put it back in it's
            % original order
            [~,i] = sort(time);
            name = name(i);
            sid = sid(i);
            
            % set up the return structure
            studies = struct;
            studies.name = name;
            studies.id = sid;
        end
        
        function pars = loadPars(obj,exp)
            expPath = fullfile(obj.path,exp);
            
            % load parameter files
            procpath = fullfile(expPath,'procpar');
            procpar = remmi.vendors.parsVarian(procpath);
            
            % set the basic remmi experimental parameters
            % echo time
            if isfield(procpar,'TE')
                pars.te = procpar.TE(:)/1000; % s
            else
                pars.te = procpar.te(:); % s
            end
            pars.nte = numel(pars.te);
            
            % TR
            pars.tr = procpar.tr(:); % s
            
            if isfield(procpar,'ti')
                pars.ti = procpar.ti;
            end
            if isfield(procpar,'td')
                pars.td = procpar.td;
            end
            
%             % Load parameters if this is an MTIR dataset
%             if isfield(procpar,'REMMI_MtIrOnOff') && ...
%                         strcmp(procpar.REMMI_MtIrOnOff,'Yes');
%                 if isfield(procpar,'REMMI_MtIrTimeArr')
%                     pars.ti = procpar.REMMI_MtIrTimeArr(:)/1000; % s
%                 elseif isfield(procpar,'InversionTime')
%                     pars.ti = procpar.InversionTime(:)/1000; % s
%                 end
% 
%                 % TD, if exists
%                 if isfield(procpar,'REMMI_MtTDTime')
%                     pars.td = procpar.REMMI_MtTDTime(:)/1000; % s
%                 elseif isfield(procpar,'RepetitionDelayTime')
%                     pars.td = procpar.RepetitionDelayTime(:)/1000; % s
%                 end
%             end
            
            % vendor and sequence
            pars.vendor = 'Varian';
            pars.sequence = procpar.seqfil;

            % time the data was acquired
            val = procpar.time_complete;
            if ~strcmp(val,'na')
                val = remmi.vendors.Varian.parsetime(val);
            end
            pars.time = val;
            pars.timestr = datestr(val);

            % store all the other parameters, in case someone needs them
            pars.procpar = procpar;
        end
        
        function [img,labels,pars] = load(obj,exp,opts)
            % load parameters
            pars = obj.loadPars(exp);
            
            % load images
            expPath = fullfile(obj.path,exp);
            raw = remmi.vendors.loadVarian(expPath,pars.procpar);
            img = remmi.recon.ft(raw,opts);
            
            sz = size(img);
            if size(img,length(obj.labels))==1
                sz(length(obj.labels)) = 1;
            end
            
            labels = obj.labels(sz>1);
            img = squeeze(img);
        end
    end
end