classdef BrukerPV < handle
    % BrukerPV is a class used to identify and reconstruct Bruker
    % Paravision datasets and images. 
    properties
        path
        labels= {'RO','PE1','PE2','NE','NC','NS','DW','IR','MT','BS','NR'};
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
                warning('Study is not valid: %s',spath);
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
                    time(n) = acqpars.ACQ_abs_time(1); %remmi.vendors.BrukerPV.parsetime(acqpars.ACQ_time);
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
            
            % FOV
            pars.fov = methpars.PVM_Fov; % mm
            
            % Load parameters if this is an MTIR dataset
            if isfield(methpars,'REMMI_MtIrOnOff') && ...
                        strcmp(methpars.REMMI_MtIrOnOff,'Yes');
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
            end
            
            % for offset MT sequences, what is the range in frequence
            % offsets, and rf power?
            if isfield(methpars,'PVM_MagTransOnOff')
                if strcmp(methpars.PVM_MagTransOnOff,'On')
                    pars.mt_offset = methpars.PVM_MagTransFL;
                    pars.mt_power = methpars.PVM_MagTransPower;
                end
            end
            
            % vendor and sequence
            pars.vendor = 'Bruker';
            pars.sequence = methpars.Method;

            % time the data was acquired
            pars.time = datetime(acqpars.ACQ_abs_time,'convertfrom','posixtime');

            % store all the other parameters, in case someone needs them
            pars.methpars = methpars;
            pars.acqpars = acqpars;
        end
        
        function [img,labels,pars] = load(obj,exp,opts)
            % load parameters
            pars = obj.loadPars(exp);
            
            % load images
            expPath = fullfile(obj.path,exp);
            if contains(pars.methpars.Method,'remmiGRASE')%strcmp(pars.methpars.Method,'<User:remmiGRASE>')
                % do the GRASE reconstruction
                raw = remmi.vendors.loadBrukerGrase(expPath,pars.methpars,pars.acqpars);
            else
                raw = remmi.vendors.loadBruker(expPath,pars.methpars);
            end
            
            % partial fourier acquisitions have a large percent of 
            % signals==0
            if sum(raw(:)==0)/numel(raw)>0.01
                % this is a partial fourier acquisition. Fill in with POCS
                raw = remmi.recon.pocs(raw);
            end
            
            img = remmi.recon.ft(raw,opts);
            
            % coil combinations
            coil_idx = find(ismember(obj.labels,{'NC'}));
            if size(img,coil_idx) > 1
                % for now, just sum of squares coil combination
                img = sqrt(sum(img.*conj(img),coil_idx));
            end
            
            sz = size(img);
            if size(img,length(obj.labels))==1
                sz(length(obj.labels)) = 1;
            end
            
            labels = obj.labels(sz>1);
            img = squeeze(img);
        end

        function [img,labels,pars] = loadImg(obj,exp1,opts)
            % load parameters
            pars = obj.loadPars(exp1);

            % custom hack for PE reversed EPI
            rid = '1';
            if exist('opts','var')
                if isfield(opts,'id')
                    rid = opts.id;
                end
            end

            pars.recopars = remmi.vendors.parsBruker(fullfile(obj.path,exp1,...
                'pdata',rid,'reco'));
                      
            fileName = fullfile(obj.path,exp1,'pdata',rid,'2dseq');
            fid=fopen(fileName);
            if fid < 0
                error('cannot open %s',fileName)
            end
            % 2dseq is formated 16 bit signed integer
            raw=fread(fid,'int16'); 
            fclose(fid);
            
            img = reshape(raw,pars.recopars.RECO_size(1),...
                pars.recopars.RECO_size(2),...
                pars.recopars.RecoObjectsPerRepetition,[]);

            if isfield(pars.methpars,'PhaseEncodeReversed')
                if isfield(pars.methpars,'PVM_EffPhase1Offset')
                    if strcmp(pars.methpars.PhaseEncodeReversed,'Yes')
                        proj = fftshift(fft(fftshift(img,2),[],2),2);
                        % reverse the PE2 direction x2
                        np = pars.methpars.PVM_Matrix(2);
                        line = reshape((1:np) - 1 - round(np/2),1,[]);
                        ph1_offset = reshape(pars.methpars.PVM_EffPhase1Offset,1,1,[]);
                        phroll = exp(2*1i*2*pi*bsxfun(@times,line,ph1_offset)/pars.methpars.PVM_Fov(2));
                        proj = bsxfun(@times,proj,phroll);

                        img = abs(ifftshift(fft(ifftshift(proj,2),[],2),2));
                    end
                end
            end

            img = squeeze(img);
            labels = {}; % no labels yet
        end
    end
end