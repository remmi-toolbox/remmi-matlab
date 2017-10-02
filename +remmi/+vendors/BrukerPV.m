classdef BrukerPV < handle
    % BrukerPV is a class used to identify and reconstruct Bruker
    % Paravision datasets and images. 
    properties
        path
        labels= {'RO','PE1','PE2','NE','NS','DW','IR','MT','NR'};
    end
    
    methods(Static)
        function bool = isValid(spath)
            bool = exist(fullfile(spath,'subject'),'file') == 2;
        end
        
        function time = parsetime(val)
            try
                time = datenum(val,'HH:MM:SSddmmmyyyy');
            catch 
                try
                    i1 = strfind(val,'<');
                    i2 = strfind(val,'>');
                    val = remmi.util.strsplit(val(i1+1:i2-1),',');
                    time = datenum(val{1},'yyyy-mm-ddTHH:MM:SS');
                catch
                    time = 0;
                end
            end
        end
    end
    
    methods
        function obj = BrukerPV(spath)
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
            methpath = fullfile(expPath,'method');
            methpars = remmi.vendors.parsBruker(methpath);

            acqpath = fullfile(expPath,'acqp');
            acqpars = remmi.vendors.parsBruker(acqpath);
            
            % set the basic remmi experimental parameters
            % echo time
            if isfield(methpars,'EffectiveTE')
                pars.te = methpars.EffectiveTE(:)/1000; % s
            else
                pars.te = methpars.PVM_EchoTime(:)/1000; % s
            end
            pars.nte = methpars.PVM_NEchoImages;
            
            % TR
            pars.tr = methpars.PVM_RepetitionTime(:)/1000; % s
            if isfield(methpars,'REMMI_MtIrTimeArr')
                pars.ti = methpars.REMMI_MtIrTimeArr(:)/1000; % s
            elseif isfield(methpars,'InversionTime')
                pars.ti = methpars.InversionTime(:)/1000; % s
            end
            
            % TD, if exists
            if isfield(methpars,'REMMI_MtTDTime')
                pars.td = methpars.REMMI_MtTDTime(:)/1000; % s
            elseif isfield(methpars,'RepetitionDelayTime')
                pars.td = methpars.RepetitionDelayTime(:)/1000; % s
            end
            
            % for offset MT sequences, what is the range in frequence
            % offsets, and rf power?
            if isfield(methpars,'PVM_MagTransOnOff')
                if strcmp(methpars.PVM_MagTransOnOff,'On');
                    pars.mt_offset = methpars.PVM_MagTransFL;
                    pars.mt_power = methpars.PVM_MagTransPower;
                end
            end
            
            % vendor and sequence
            pars.vendor = 'Bruker';
            pars.sequence = methpars.Method;

            % time the data was acquired
            val = acqpars.ACQ_time;
            if ~strcmp(val,'na')
                val = remmi.vendors.BrukerPV.parsetime(val);
            end
            pars.time = val;

            % store all the other parameters, in case someone needs them
            pars.methpars = methpars;
            pars.acqpars = acqpars;
        end
        
        function [img,labels,pars] = load(obj,exp,opts)
            % load parameters
            pars = obj.loadPars(exp);
            
            % load images
            expPath = fullfile(obj.path,exp);
            raw = remmi.vendors.loadBruker(expPath,pars.methpars);
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