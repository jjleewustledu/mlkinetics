classdef (Abstract) ScannerKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for PET and MRI scanners used for kinetics.
    %  It is an extensible factory making using of the factory method pattern (cf. GoF pp. 90-91, 107). 
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  Disambiguate from legacy mlpet.ScannerKit.
    %  
    %  Created 02-May-2023 14:15:41 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Abstract)
        do_make_device(this) % incorporates calibrations
    end

    properties (Dependent)
        decayCorrected
        noclobber % minimize writing large NIfTI to filesystem
    end

    methods %% GET, SET
        function g = get.decayCorrected(this)
            if isempty(this.device_)
                this.do_make_device();
            end
            g = this.device_.decayCorrected;
        end
        function g = get.noclobber(this)
            g = this.noclobber_;
        end
        function     set.noclobber(this, s)
            assert(islogical(s))
            this.noclobber_ = s;
        end
    end

    methods
        function this = decayCorrect(this)
            if isempty(this.device_)
                this.do_make_device();
            end
            decayCorrect(this.device_);
            this.imaging_context_ = [];
        end
        function this = decayUncorrect(this)
            if isempty(this.device_)
                this.do_make_device();
            end
            decayUncorrect(this.device_);
            this.imaging_context_ = [];
        end

        %% make related products, with specialty relationships specified by the factory

        function ic = do_make_activity(this, varargin)
            %% Bq
            %  decayCorrected logical = false.
 			%  datetimeForDecayCorrection datetime = NaT, updates internal.
            %  index0 double {@isnumeric} = this.index0
            %  indexF double {@isnumeric} = this.indexF
            %  timeAveraged logical = false
            %  volumeAveraged logical = false.
            %  diff logical = false.
            %  uniformTimes logical = false, applicable only if volumeAveraged.
            %  typ text = 'single'.

            dev = do_make_device(this);
            a = dev.activity('typ', 'mlfourd.ImagingContext2', varargin{:});
            ic = this.do_make_imaging(a);
        end
        function ic = do_make_activity_density(this, varargin)
            %% Bq/mL
            %  decayCorrected logical = false.
 			%  datetimeForDecayCorrection datetime = NaT, updates internal.
            %  index0 double {@isnumeric} = this.index0
            %  indexF double {@isnumeric} = this.indexF
            %  timeAveraged logical = false
            %  volumeAveraged logical = false.
            %  diff logical = false.
            %  uniformTimes logical = false, applicable only if volumeAveraged.
            %  typ text = 'single'.

            dev = do_make_device(this);
            a = dev.activityDensity('typ', 'mlfourd.ImagingContext2', varargin{:});
            ic = this.do_make_imaging(a);
        end
        function ic = do_make_imaging(this, measurement)
        function ic = do_make_imaging(this, measurement_ic)
            %% provides class-consistent fqfp and noclobber info to measurement

            arguments
                this mlkinetics.ScannerKit
                measurement_ic mlfourd.ImagingContext2
            end
            med_ = this.bids_kit_.make_bids_med();
            ic_ = med_.imagingContext;
            fp_ = ic_.fqfileprefix;
            if ~contains(fp_, stackstr(3, use_dashes=true))
                fp_ = mlpipeline.Bids.adjust_fileprefix( ...
                    ic_.fileprefix, post_proc=stackstr(3, use_dashes=true));
            end
            ic = measurement_ic;
            ic.fileprefix = fp_;
            ic.noclobber = this.noclobber;
        end
        function ic = do_make_view(this)
            if isempty(this.device_)
                do_make_device(this);
            end
            ic = this.device_.activityDensity('typ', 'mlfourd.ImagingContext2');
            ic.view();
        end
        function h = do_make_plot(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            h = this.device_.plot(varargin{:});
        end        
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.ScannerKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
    end

    methods (Static)
        
        %% convenience create-methods for clients

        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
                opts.scanner_tags {mustBeText}
            end
            copts = namedargs2cell(opts);

            if any(contains(opts.scanner_tags, "vision", IgnoreCase=true))
                this = mlsiemens.BiographVisionKit2.instance(copts{:});
                return
            end
            if any(contains(opts.scanner_tags, "mmr", IgnoreCase=true))
                this = mlsiemens.BiographMMRKit2.instance(copts{:});
                return
            end
            if any(contains(opts.scanner_tags, "ecat", IgnoreCase=true))
                if any(contains(opts.scanner_tags, "hrrt", IgnoreCase=true))
                    this = mlsiemens.EcatHrrtKit.instance(copts{:});
                    return
                end
                if any(contains(opts.scanner_tags, "hr+", IgnoreCase=true))
                    this = mlsiemens.EcatExactHRPlusKit.instance(copts{:});
                    return
                end
                if any(contains(opts.scanner_tags, "hr", IgnoreCase=true))
                    this = mlsiemens.EcatExactHRKit.instance(copts{:});
                    return
                end
            end
        end

        %% utilities

        function [arterialDev,arterialDatetimePeak] = alignArterialToScanner(varargin)
            %% ALIGNARTERIALTOSCANNER
            %  @param required arterialDev is counting device or arterial sampling device, as mlpet.AbstractDevice.
            %  @param required scannerlDev is mlpet.AbstractDevice.
            %  @param sameWorldline is logical.  Set true to avoid worldline shifts between arterial & scanner data.
            %  @return arterialDev, modified if not sameWorldline;
            %  @return arterialDatetimePeak, updated with alignments.
            %  @return arterialDev.Dt, always updated.
            %  @return updates mlraichle.StudyRegistry.tBuffer.
            
            ip = inputParser;
            addRequired(ip, 'arterialDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'sameWorldline', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            ad = mlaif.AifData.instance();
            arterialDev = copy(ipr.arterialDev);
            scannerDev = ipr.scannerDev;

            % find Dt of carotid bolus from radial-artery bolus, unresolved frames-of-reference
            unifTimes = 0:max(arterialDev.timeWindow, scannerDev.timesMid(end));
            arterialDevTimes = arterialDev.times(arterialDev.index0:arterialDev.indexF) - arterialDev.time0;
            arterialAct = interp1(arterialDevTimes, ...
                                 arterialDev.activityDensity(), ...
                                 unifTimes);
            scannerAct = interp1(scannerDev.timesMid, ...
                                scannerDev.activityDensity('volumeAveraged', true), ...
                                unifTimes);
            dscannerAct = movmean(diff(scannerAct), 9);
            if ~isempty(getenv('DEBUG'))
                figure; plot(unifTimes(1:end-1), diff(scannerAct));
                hold on
                plot(unifTimes(1:end-1), dscannerAct);
                hold off
                ylabel('activity density (Bq/mL)')
                title(stackstr())
            end

            thresh = 0.9; %arterialDev.threshOfPeak;
            [~,idxScanner] = max(dscannerAct > thresh*max(dscannerAct));
            [~,idxArterial] = max(arterialAct > thresh*max(arterialAct));
            tArterial = seconds(unifTimes(idxArterial));
            tScanner = seconds(unifTimes(idxScanner));
            
            % manage failures of interp1()
            if tArterial > seconds(0.5*scannerDev.timeWindow)
                warning('mlkinetics:ValueError', ...
                    '%s.tArterial was %g but arterialDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
                ad.stableToInterpolation = false;
                [~,idxArterial] = max(arterialDev.activityDensity() > thresh*max(arterialDev.activityDensity()));
                tArterial = seconds(arterialDevTimes(idxArterial));
                fprintf('tArterial forced-> %g\n', seconds(tArterial))
            end            
            if tArterial > seconds(0.5*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlkinetics:ValueError', ...
                    '%s.tArterial was %g but arterialDev.timeWindow was %g.', ...
                    stackstr(), seconds(tArterial), arterialDev.timeWindow)
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow)
                warning('mlkinetics:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.\n', ...
                    stackstr(), seconds(tScanner), scannerDev.timeWindow)
                ad.stableToInterpolation = false;
                scannerDevAD = scannerDev.activityDensity('volumeAveraged', true, 'diff', true);
                [~,idxScanner] = max(scannerDevAD > thresh*max(scannerDevAD));
                tScanner = seconds(scannerDev.timesMid(idxScanner));
                fprintf('tScanner forced -> %g\n', seconds(tScanner))
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlkinetics:ValueError', ...
                    '%s.tScanner was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(tScanner), scannerDev.timeWindow)
            end
            
            % resolve frames-of-reference, ignoring delay of radial artery from carotid
            Dbolus = scannerDev.datetime0 + tScanner - (arterialDev.datetime0 + tArterial);
            arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                            tScanner - ...
                                            tArterial - ...
                                            Dbolus;
                                        
            % manage failures of Dbolus
            if Dbolus > seconds(15)
                warning('mlkinetics:ValueError', ...
                    '%s.Dbolus was %g.\n', stackstr(), seconds(Dbolus))
                fprintf('scannerDev.datetime0 was %s.\n', datestr(scannerDev.datetime0))
                fprintf('tScanner was %g.\n', seconds(tScanner))
                fprintf('arterialDev.datetime0 was %s.\n', datestr(arterialDev.datetime0))
                fprintf('tArterial was %g.\n', seconds(tArterial))
                Dbolus = seconds(15);
                arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                                tScanner - ...
                                                tArterial - ...
                                                Dbolus;
                fprintf('Dbolus forced -> %g\n', seconds(Dbolus))
                fprintf('arterialDev.datetimeMeasured forced -> %s\n', ...
                        datestr(arterialDev.datetimeMeasured))
            end
            if abs(Dbolus) > seconds(0.5*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlkinetics:ValueError', ...
                    '%s.Dbolus was %g but scannerDev.timeWindow was %g.', ...
                    stackstr(), seconds(Dbolus), scannerDev.timeWindow)
                %Dbolus = seconds(0);
                %arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0;
                %warning('mlkinetics:ValueError', ...
                %        'BiographKit.alignArterialToScanner.Dbolus forced -> %g', seconds(Dbolus))
                %warning('mlkinetics:ValueError', ...
                %        'BiographKit.alignArterialToScanner.arterialDev.datetimeMeasured forced -> %s', ...
                %        datestr(arterialDev.datetimeMeasured))
            end
                                        
            % adjust arterialDev worldline to describe carotid bolus
            if ipr.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + Dbolus;
            else
                arterialDev.shiftWorldlines(seconds(Dbolus));
            end
            arterialDev.Dt = seconds(Dbolus);
            arterialDatetimePeak = arterialDev.datetime0 + tArterial;
            
            % tBuffer
            ad.Ddatetime0 = seconds(scannerDev.datetime0 - arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = scannerDev.datetimeForDecayCorrection;            
        end        
        function mixed = mixImagingContexts(obj, obj2, f, varargin)
            %  Args:
            %      obj is understood by mlfourd.ImagingContext2
            %      obj2 is understood by mlfourd.ImagingContext2
            %      f is fraction of obj mixed with obj2

            ip = inputParser;
            addRequired(ip, 'obj')
            addRequired(ip, 'obj2')
            addRequired(ip, 'f', @isscalar)
            addOptional(ip, 'daif', nan, @isscalar)
            parse(ip, obj, obj2, f, varargin{:})
            
            assert(f > 0)
            assert(f < 1)
            if isnumeric(obj) && isnumeric(obj2)
                mixed = f*obj + (1 - f)*obj2;
                return
            end
            obj = mlfourd.ImagingContext2(obj);
            obj2 = mlfourd.ImagingContext2(obj2);
            mixed = obj * f + obj2 * (1 - f);
            if isfinite(ip.Results.daif)
                mixed.fileprefix = sprintf('%s_daif%s', ...
                    mixed.fileprefix, strrep(num2str(ip.Results.daif, 4), '.', 'p'));
            end            
        end
        function [scan_,timesMid_,aif_] = mixScannersAifsAugmented(varargin)
            
            import mlkinetics.ScannerKit
            import mlkinetics.ScannerKit.mixImagingContexts
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'DtMixing', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            DtMixing = ipr.DtMixing;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            scan = scanner.activityDensity();
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);            
            scan2 = scanner2.activityDensity();
            
            % arterials also have calibrations
            
            a = ipr.arterial;
            aif = a.activityDensity();         
            a2 = ipr.arterial2;
            aif2 = a2.activityDensity();
            
            % reconcile timings  
              
            t_a = 0:a.timeWindow;
            t_a2 = 0:a2.timeWindow;
            
            if DtMixing < 0 % shift aif2, scan2 to left             
                aif = makima(t_a + a.Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_a2 + a2.Dt + DtMixing, aif2, 0:scanner.times(end));
                scan2 = makima(scanner2.times + DtMixing, scan2, scanner.times); 
                timesMid_ = scanner.timesMid;
            else % shift aif, scan to left
                aif2 = makima(t_a2 + a2.Dt, aif2, 0:scanner2.times(end));
                aif = makima(t_a + a.Dt - DtMixing, aif, 0:scanner2.times(end));
                scan = makima(scanner.times - DtMixing, scan, scanner2.times);  
                timesMid_ = scanner2.timesMid;
            end 
            aif(aif < 0) = 0;
            scan(scan < 0) = 0;
            aif2(aif2 < 0) = 0;
            scan2(scan2 < 0) = 0;
            
            scan_ = mixImagingContexts(scan, scan2, ipr.fracMixing); % calibrated, decaying
            aif_ = mixImagingContexts(aif, aif2, ipr.fracMixing);
        end
        function [tac__,timesMid__,t0__,aif__,Dt,datetimePeak] = mixTacAif(devkit, varargin)
            %  @return taus__ are the durations of emission frames
            %  @return t0__ is the start of the first emission frame.
            %  @return aif__ is aligned in time to emissions.
            %  @return Dt is the time shift needed to align aif to emissions.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'scanner_kit', [], @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'input_func_kit', [], @(x) isa(x, 'mlkinetics.InputFuncKit'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;
            if isa(ipr.input_func_kit, "mlkinetics.IdifKit")
                [tac__,timesMid__,t0__,aif__,Dt,datetimePeak] = ...
                    mlkinetics.ScannerKit.mixTacIdif(devkit, varargin{:});
                return
            end
            ipr.roi = ipr.roi.binarized();
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-masking    
            %blur = ipr.devkit.sessionData.petPointSpread;
            sk = ipr.scanner_kit; 
            s = sk.do_make_device();
            s = s.masked(ipr.roi);
            tac = s.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            tac(tac < 0) = 0;    
            tac = ad.normalizationFactor*tac; % empirical normalization                   
            tac__ = tac;
            taus__ = s.taus;
            timesMid__ = s.timesMid;
            Nt = ceil(timesMid__(end));
            
            % estimate t0__
            tac_avgxyz = squeeze(mean(mean(mean(tac__, 1), 2), 3));
            dtac_avgxyz = diff(tac_avgxyz);
            [~,idx] = max(dtac_avgxyz > 0.05*max(dtac_avgxyz));
            t0__ = timesMid__(idx) - taus__(idx)/2;
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series  
            ifk = ipr.input_func_kit;
            a0 = ifk.do_make_device();
            [a, datetimePeak] = mlkinetics.ScannerKit.alignArterialToScanner( ...
                a0, s, 'sameWorldline', false);
            aif = a.activityDensity(Nt=Nt, decayCorrected=ipr.scanner_kit.decayCorrected);
            switch class(a)
                case 'mlswisstrace.TwiliteDevice'
                    t = (0:Nt-1) - seconds(s.datetime0 - a.datetime0);
                case 'mlcapintec.CapracDevice'
                    t = a.times - seconds(s.datetime0 - a.datetime0);
                otherwise
                    error('mloxygen:ValueError', ...
                        'class(AugmentedData.mixTacAif.a) = %s', class(a))
            end
            
            % adjust aif__, get Dt
            if length(t) > length(aif)
                t = t(1:length(aif));
            end
            if length(aif) > length(t)
                aif = aif(1:length(t));
            end
            if min(t) > 0
                aif = interp1([0 t], [0 aif], 0:s.timesMid(end), 'linear', 0);
            else                
                aif = interp1(t, aif, 0:s.timesMid(end), 'linear', 0);
            end
            aif(aif < 0) = 0;            
            aif__ = aif;            
            Dt = a.Dt;
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacAifAugmented(devkit, varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;      
            if strcmp(class(ipr.scanner), class(ipr.arterial))
                [tac__,timesMid__,aif__,Dt,datetimePeak] = ...
                    mlkinetics.ScannerKit.mixTacIdif(devkit, varargin{:});
                return
            end
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            tac(tac < 0) = 0;                       
            tac = ad.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            Nt = ceil(timesMid__(end));
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series            
            a0 = ipr.arterial;
            [a, datetimePeak] = devkit.alignArterialToScanner( ...
                a0, s, 'sameWorldline', false);
            aif = a.activityDensity(Nt=Nt, decayCorrected=ipr.scanner_kit.decayCorrected);
            switch class(a)
                case 'mlswisstrace.TwiliteDevice'
                    t = (0:Nt-1) - seconds(s.datetime0 - a.datetime0);
                case 'mlcapintec.CapracDevice'
                    t = a.times - seconds(s.datetime0 - a.datetime0);
                otherwise
                    error('mlpet:ValueError', ...
                        'class(AugmentedData.mixTacAif.a) = %s', class(a))
            end
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-ad.tBuffer == t)
                ad.T = ad.T + 1;
            end
            aif = interp1([-ad.tBuffer t], [0 aif], -ad.tBuffer:s.timesMid(end), 'linear', 0);
            aif(aif < 0) = 0;            
            aif__ = aif;            
            Dt = a.Dt;
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacAifHybrid(devkit, varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @iscell)
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;      
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            tac(tac < 0) = 0;                       
            tac = ad.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            Nt = ceil(timesMid__(end));
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series  
            [a1, datetimePeak] = devkit.alignArterialToScanner( ...
                ipr.arterial{1}, s, 'sameWorldline', false);
            Dt = a1.Dt;
            aif1 = a1.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected); % 1 Hz Twilite
            aif2 = ipr.arterial{2}.activityDensityInterp1(decayCorrected=ipr.scanner_kit.decayCorrected); % 1 Hz interp1 of Caprac
            daif = aif1(end) - aif2(1);
            aif = [aif1, aif2+daif];
            if length(aif) > Nt
                aif = aif(1:Nt); % truncate late aif
            elseif length(aif) < Nt
                Nremain = Nt - length(aif);
                aif = [aif, aif(end)*ones(1,Nremain)]; % extrapolate late aif
            end
            t = (0:Nt-1) - seconds(s.datetime0 - a1.datetime0);
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-ad.tBuffer == t)
                ad.T = ad.T + 1;
            end
            aif = interp1([-ad.tBuffer t], [0 aif], -ad.tBuffer:s.timesMid(end), 'linear', 0);
            aif(aif < 0) = 0;   
            aif__ = aif;
        end        
        function [tac__,timesMid__,t0__,idif__,Dt,datetimePeak] = mixTacIdif(devkit, varargin)
            %  @return taus__ are the durations of emission frames
            %  @return t0__ is the start of the first emission frame.
            %  @return idif__ is aligned in time to emissions.
            %  @return Dt is the time shift needed to align aif to emissions.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'scanner_kit', [], @(x) isa(x, 'mlkinetics.ScannerKit'))
            addParameter(ip, 'input_func_kit', [], @(x) isa(x, 'mlkinetics.InputFuncKit'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;
            ipr.roi = ipr.roi.binarized();
            
            % scannerDevs provide calibrations & ROI-masking    
            %blur = ipr.devkit.sessionData.petPointSpread;
            sk = ipr.scanner_kit; 
            s = sk.do_make_device();
            s = s.masked(ipr.roi);
            tac = s.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            tac(tac < 0) = 0;                       
            tac__ = tac;
            taus__ = s.taus;
            timesMid__ = s.timesMid;
            
            % estimate t0__
            tac_avgxyz = squeeze(mean(mean(mean(tac__, 1), 2), 3));
            dtac_avgxyz = diff(tac_avgxyz);
            [~,idx] = max(dtac_avgxyz > 0.05*max(dtac_avgxyz));
            t0__ = timesMid__(idx) - taus__(idx)/2;
            
            % idif
            ifk = ipr.input_func_kit;
            idif = ifk.do_make_activity_density(decayCorrected=ipr.scanner_kit.decayCorrected);   
            idif = asrow(idif.imagingFormat.img);
            t = s.timesMid;
            
            % adjust aif__
            idif = interp1([0 t], [0 idif], 0:s.timesMid(end), 'linear', 0);
            idif(idif < 0) = 0;            
            idif__ = idif; 

            % trivial values
            Dt = 0;
            datetimePeak = NaT;
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacsAifsAugmented(devkit, devkit2, varargin)
            
            import mlkinetics.ScannerKit
            import mlkinetics.ScannerKit.mixTacAifAugmented
            import mlkinetics.ScannerKit.mixImagingContexts
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlkineticsc.ScannerKit'))
            addRequired(ip, 'devkit2', @(x) isa(x, 'mlkineticsc.ScannerKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'DtMixing', 0, @isscalar) % sec > 0
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, devkit, devkit2, varargin{:})
            ipr = ip.Results;
            s = ipr.scanner;
            s2 = ipr.scanner2;
            ad = mlaif.AifData.instance();
            
            % align aif with tac, aif2 with tac2
            [tac,timesMid,aif,Dt,datetimePeak] = mixTacAifAugmented(devkit, ...
                                                           'scanner', ipr.scanner, ...
                                                           'arterial', ipr.arterial, ...
                                                           'roi', ipr.roi);                                                
            [tac2,~,aif2,~,datetimePeak2] = mixTacAifAugmented(devkit2, ...
                                                      'scanner', ipr.scanner2, ...
                                                      'arterial', ipr.arterial2, ...
                                                      'roi', ipr.roi2);
            offset = seconds(datetimePeak - s.datetime0) - ...
                     seconds(datetimePeak2 - s2.datetime0) + ...
                     ipr.DtMixing;
            
            % align tac2 with tac
            tac = interp1([-1 s.timesMid], [0 tac], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac2 = interp1((offset + [-1 s2.timesMid]), [0 tac2], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac__ = mixImagingContexts(tac, tac2, ipr.fracMixing); 
            tac__ = interp1(s.timesMid(1):s.timesMid(end), tac__, s.timesMid, 'linear', 0);
            tac__(tac__ < 0) = 0;                       
            tac__ = ad.normalizationFactor*tac__; % empirical normalization
            timesMid__ = timesMid;
            
            % align aif2 with aif
            n = length(aif);
            n2 = length(aif2);
            aif2 = interp1(offset + (0:n2-1), aif2, 0:n-1, 'linear', 0);
            aif__ = mixImagingContexts(aif, aif2, ipr.fracMixing); 
            aif__(aif__ < 0) = 0;  
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacIdifAugmented(devkit, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mmlkineticsc.ScannerKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            tac(tac < 0) = 0;                       
            tac = ad.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series 
            a = ipr.arterial;
            aif = a.activityDensity(decayCorrected=ipr.scanner_kit.decayCorrected);
            t = a.timesMid;
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-ad.tBuffer == t)
                ad.T = ad.T + 1;
            end
            aif = interp1([-ad.tBuffer t], [0 aif], -ad.tBuffer:s.timesMid(end), 'linear', 0);
            aif(aif < 0) = 0;            
            aif__ = aif;  

            % trivial values
            Dt = 0;
            datetimePeak = NaT;
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_
        device_
        tracer_kit_
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.tracer_kit_)
                that.tracer_kit_ = copy(this.tracer_kit_); end
        end        
        function install_scanner(this, opts)
            arguments
                this mlkinetics.ScannerKit
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
                opts.scanner_tags {mustBeText}
            end
            this.bids_kit_ = opts.bids_kit;
            this.tracer_kit_ = opts.tracer_kit;
        end
        function this = ScannerKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
