classdef BrukerPV < handle
    properties
        path
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
                    val = strsplit(val(i1+1:i2-1),',');
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
            exps = dir(obj.path);
            time = zeros(size(exps))-1;
            studies = {exps.name};
            for n=1:length(exps)
                try
                    acqpars = remmi.vendors.parsBruker(fullfile(obj.path,studies{n},'acqp'));
                    time(n) = remmi.vendors.BrukerPV.parsetime(acqpars.ACQ_time);
                catch
                end
            end
            [~,i] = sort(time);
            mask = time>=0;
            studies = studies(i);
            studies = studies(mask(i));
        end
        
        function pars = loadPars(obj,exp)
            expPath = fullfile(obj.path,exp);
            
            % load parameter files
            methpath = fullfile(expPath,'method');
            methpars = remmi.vendors.parsBruker(methpath);

            acqpath = fullfile(expPath,'acqp');
            acqpars = remmi.vendors.parsBruker(acqpath);
            
            % set the basic remmi experimental parameters
            if isfield(methpars,'EffectiveTE')
                pars.te = methpars.EffectiveTE;
            else
                pars.te = methpars.PVM_EchoTime;
            end
            pars.nte = methpars.PVM_NEchoImages;
            pars.tr = methpars.PVM_RepetitionTime;
            if isfield(methpars,'REMMI_MtIrTimeArr')
                pars.ti = methpars.REMMI_MtIrTimeArr;
            elseif isfield(methpars,'InversionTime')
                pars.ti = methpars.InversionTime;
            end
            if isfield(methpars,'REMMI_MtTDTime')
                pars.td = methpars.REMMI_MtTDTime;
            elseif isfield(methpars,'RepetitionDelayTime')
                pars.td = methpars.RepetitionDelayTime;
            end
            pars.vendor = 'Bruker';
            pars.sequence = methpars.Method;

            val = acqpars.ACQ_time;
            if ~strcmp(val,'na')
                val = remmi.vendors.BrukerPV.parsetime(val);
            end
            pars.time = val;

            % store all the other parameters, in case someone needs them
            pars.methpars = methpars;
            pars.acqpars = acqpars;
        end
        
        function [img,pars] = load(obj,exp)
            % load parameters
            pars = obj.loadPars(exp);
            
            % load images
            expPath = fullfile(obj.path,exp);
            img = abs(remmi.vendors.loadBruker(expPath,pars.methpars));
        end
    end
end