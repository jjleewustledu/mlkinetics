classdef (Abstract) Model < handle & mlsystem.IHandle
    %% The mlkinetics.Model class hierarchy loosely implements the builder design pattern (GoF, pp. 97ff.).  
    %  Subclasses should implement static create() that provides class constructors. 
    %  Method function build_solution() should update the product property and return it.
    %  The director of the builder should be an mlkinetics.ModelKit. 
    %  
    %  Created 13-Jun-2023 22:58:44 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Abstract)
        build_solution(this)
    end

    methods (Abstract, Static)
        create()
        sampled(ks, Data, artery_interpolated, times_sampled) 
        % artery_interpolated has uniform sampling; times_sampled may be non-uniform
    end

    %% Shared Implementations

    properties
        Data % struct of ancillary data shared with solver
    end

    properties (Dependent)
        bids_med % from BidsKit
        data % struct of ancillary data provided by ModelKit
        dlicv_ic % coregistered to dynamic PET
        input_func % from InputFuncKit
        mgdL_to_mmolL % [mg/dL] * mgdL_to_mmolL -> [mmol/L]
        model % reference loopback provides legacy support
        parc % from ParcKit
        product % intermediate from ScannerKit.do_make_activity_density(); final product
        tF % see also tauObs
        unique_indices

        %% lazy initialization by mixTacAif()

        artery_interpolated
        datetimePeak
        Dt
        measurement % numeric representation expected by solvers
        t0
        times_sampled
    end

    methods %% GET
        function g = get.artery_interpolated(this)
            if ~isempty(this.artery_interpolated_)
                g = this.artery_interpolated_;
                return
            end
            [~,~,~,g] = mixTacAif(this);
            this.artery_interpolated_ = g;
        end
        function g = get.bids_med(this)
            if ~isempty(this.bids_med_)
                g = this.bids_med_;
                return
            end

            this.bids_med_ = this.bids_kit_.make_bids_med();
            g = this.bids_med_;
        end
        function g = get.data(this)
            g = this.data_;
        end
        function g = get.datetimePeak(this)
            if ~isempty(this.datetimePeak_)
                g = this.datetimePeak_;
                return
            end
            [~,~,~,~,~,g] = mixTacAif(this);
            this.datetimePeak_ = g;
        end
        function g = get.dlicv_ic(this)
            g = this.parc.dlicv_ic;
        end
        function g = get.Dt(this)
            if ~isempty(this.Dt_)
                g = this.Dt_;
                return
            end
            [~,~,~,~,g] = mixTacAif(this);
            this.Dt_ = g;
        end
        function g = get.input_func(this)
            if ~isempty(this.input_func_)
                g = this.input_func_;
                return
            end
            this.input_func_ = this.input_func_kit_.do_make_activity_density();
            g = this.input_func_;
        end
        function g = get.measurement(this)
            if ~isempty(this.measurement_)
                g = this.measurement_;
                return
            end
            g = mixTacAif(this);
            this.measurement_ = g;
        end
        function g = get.mgdL_to_mmolL(this)
            if isfield(this.data, "mgdL_to_mmolL")
                g = this.data.mgdL_to_mmolL_;
                return
            end
            if isfield(this.data, "molecular_weight")
                g = 10/this.data.molecular_weight;
                return
            end
            g = nan;
        end
        function g = get.model(this)
            g = this;
        end
        function g = get.parc(this)
            if ~isempty(this.parc_)
                g = this.parc_;
                return
            end

            this.parc_ = this.parc_kit_.make_parc();
            g = this.parc_;
        end
        function g = get.product(this)
            if ~isempty(this.product_)
                g = copy(this.product_);
                return
            end

            % defaults to starting data which is lazy init from ScannerKit
            this.product_ = this.scanner_kit_.do_make_activity_density();
            g = this.product_;
        end
        function g = get.unique_indices(this)
            g = this.parc.unique_indices;
        end
        function g = get.t0(this)
            if ~isempty(this.t0_)
                g = this.t0_ + this.timeStar();
                return
            end
            [~,~,g_] = mixTacAif(this);
            this.t0_ = g_;
            g = this.t0_ + this.timeStar();
        end
        function g = get.tF(this)
            g = min(this.t0 + this.tauObs(), this.timeCliff());
        end
        function g = get.times_sampled(this)
            if ~isempty(this.times_sampled_)
                g = this.times_sampled_;
                return
            end
            [~,g] = mixTacAif(this);
            this.times_sampled_ = g;
        end

        %% legacy support for mlpet.TracerKineticsModel
        
        function set_times_sampled(this, s)
            if isempty(s)
                return
            end
            this.times_sampled_ = asrow(s);
        end
        function set_artery_interpolated(this, s)
            if isempty(s)
                return
            end            
            
            try
                assert(~isempty(this.times_sampled))
                s = double(s); % ImagingContext2 -> double
    
                % immediate match
                if length(s) == length(this.times_sampled)
                    this.artery_interpolated_ = asrow(s);
                    return
                end
    
                % artery_interpolated_ may be shorter than scanner times_sampled,
                % in which case interp1 is likely most robust
                tBuffer = 0;
                if length(s) < floor(this.times_sampled(end)) + tBuffer + 1
                    this.artery_interpolated_ = asrow( ...
                        interp1(-tBuffer:(length(s)-tBuffer-1), asrow(s), -tBuffer:this.times_sampled(end), ...
                        'linear', 0));
                    return
                end
                
                % best remaining guess
                this.artery_interpolated_ = asrow(s);
            catch ME
                handwarning(ME) % artery_interpolated_ <- mixTacAif(), usually
            end
        end
    end

    methods
        function this = initialize(this, opts)
            arguments
                this mlkinetics.Model
                opts.bids_kit = []
                opts.tracer_kit = []
                opts.scanner_kit = []
                opts.input_func_kit = []            
                opts.representation_kit = []              
                opts.parc_kit = []
                opts.data struct = struct()
                opts.model_tags = []
            end

            for f = asrow(fields(opts))
                if ~isempty(opts.(f{1}))
                    this.(strcat(f{1}, "_")) = opts.(f{1});
                end
            end
        end

        %% UTILITIES

        function tac = build_simulated(this, ks)
            %% BUILD_SIMULATED simulates tissue activity with passed and internal parameters.
            %  ks double is [k1 k2 k3 k4] ~ [f lambda PS Delta].

            arguments
                this mlkinetics.Model
                ks double
            end

            tac = this.sampled(ks, this.Data, this.artery_interpolated, this.times_sampled);
        end
        function idx = indicesToCheck(this)
            idx = this.parc.indicesToCheck();
        end
        function [measurement,times_sampled,t0,artery_interpolated,Dt,datetimePeak] = mixTacAif(this)
            %% Adapts kinetic models to legacy mixture methods enumerated in mlkinetics.ScannerKit.
            %  Updates this.{measurement_,times_sampled_,t0_,artery_interpolated_,Dt_,datetimePeak_}.

            arguments
                this mlkinetics.Model                
            end

            tic
            switch class(this.input_func_kit_)
                case 'mlcapintec.CapracKit'
                    [measurement,times_sampled,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacAif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case 'mlswisstrace.TwiliteKit'
                    [measurement,times_sampled,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacAif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case {'mlkinetics.IdifKit', 'mlkinetics.MipIdifKit', 'mlkinetics.FungIdifKit'}
                    [measurement,times_sampled,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacIdif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case 'mlkinetics.NiftiInputFuncKit'
                    ad_sk = this.scanner_kit_.do_make_activity_density();
                    measurement = ad_sk.imagingFormat.img;
                    ad_ifk = this.input_func_kit_.do_make_activity_density();
                    j = ad_ifk.json_metadata;
                    times_sampled = j.timesMid;
                    t0 = 0;
                    artery = asrow(ad_ifk.imagingFormat.img);
                    tauF = times_sampled(end) - times_sampled(end-1);
                    artery_interpolated = interp1(times_sampled, artery, 0:(times_sampled(end)+tauF/2));
                    artery_interpolated(isnan(artery_interpolated)) = 0;
                    Dt = 0;
                    [~,idxPeak] = max(artery_interpolated);
                    dev = this.scanner_kit_.do_make_device();
                    datetimePeak = dev.datetime0 + seconds(idxPeak-1);  
                case 'double' % empty
                    measurement = this.measurement_;
                    times_sampled = this.times_sampled_;
                    t0 = 0;
                    artery_interpolated = this.artery_interpolated_;
                    Dt = 0;
                    datetimePeak = NaN;
                    fprintf(stackstr()+":")
                    toc
                    return
                otherwise
                    error("mlkinetics:ValueError", "%s: unknown class %s", ...
                        stackstr(), class(this.input_func_kit_))
            end

            measurement = asrow(measurement);
            this.measurement_ = measurement;
            times_sampled = asrow(times_sampled);
            this.times_sampled_ = times_sampled;
            this.t0_ = t0;
            this.artery_interpolated_ = this.wb2plasma(asrow(artery_interpolated));
            this.Dt_ = Dt;
            this.datetimePeak_ = datetimePeak;

            fprintf(stackstr()+":")
            toc
        end
        function ic = reshape_from_parc(this, ic)
            arguments
                this mlkinetics.Model
                ic {mustBeNonempty}
            end
            ic = this.parc.reshape_from_parc(ic);
        end
        function ic = reshape_to_parc(this, ics)
            arguments
                this mlkinetics.Model
                ics {mustBeNonempty}
            end

            if iscell(ics)
                ic = ics{1};
                ifc = ic.imagingFormat;
                for idx = 2:length(ics)
                    try
                        ic_idx = ics{idx};
                        ifc_idx = ic_idx.imagingFormat;
                        N4 = size(ifc_idx.img, 4);
                        ifc.img(:,:,:,idx:idx+N4-1) = ifc_idx.img;                        
                    catch ME
                        handexcept(ME)
                    end
                end
                ic = mlfourd.ImagingContext2(ifc);
                ic.fileprefix = ic.fileprefix + "_" + stackstr();
                return
            end
            if isa(ics, "mlfourd.ImagingContext2")
                ic = this.parc.reshape_to_parc(ics); % 3D or 4D
                ic.fileprefix = ic.fileprefix + "_" + stackstr();
                return
            end
            ic = mlfourd.ImagingContext2(ics);
            ic.fileprefix = ic.fileprefix + "_" + stackstr();
        end
        function t = tauObs(this)
            %% duration of valid data ~ timeCliff - t0

            if ~isempty(this.tauObs_)
                t = this.tauObs_;
                return
            end

            this.tauObs_ = this.times_sampled(end) - this.times_sampled(1) - this.timeStar;
            t = this.tauObs_;
        end
        function t = timeCliff(this)
            %% time at which valid AIF measurements abruptly end because of experimental conditions.
            %  timeCliff <= tF, the last time recorded in dataframes.

            if ~isempty(this.timeCliff_)
                t = this.timeCliff_;
                return
            end
            
            this.timeCliff_ = this.times_sampled(end);
            t = this.timeCliff_;
        end
        function t = timeStar(~)  
            %% time at which model requirements such as steady-state or linearity are met
            t = 0;
        end
        function g = trcMassConversion(g, varargin)
            %% trivial implementation to be overloaded
        end
        function p = wb2plasma(~, wb, varargin)
            p = wb;
        end
    end

    methods (Static)
        function q1 = solutionOnScannerFrames(q, times_sampled)
            %% Selectively samples scanner activity estimated on uniform time-grid, 
            %  integrating within scanner frames.
            %  @param q is activity that is uniformly sampled in time.
            %  @param times_sampled are the times of the midpoints of scanner frames, all times_sampled > 0.
            %  @return q1 has the shape of times_sampled.
            
            if length(q) == length(times_sampled)
                q1 = q;
                return
            end
            
            times_q = times_sampled(1):(times_sampled(1)+length(q)-1);
            q1 = makima(times_q, q, times_sampled);
        end
        function q1 = solutionOnScannerFramesLegacy(q, times_sampled)
            %% Samples scanner scalar activity on times of midpoints of scanner frames.
            %  @param q that is empty resets internal data for times and q1 := [].
            %  @param q is activity that is uniformly sampled in time.
            %  @param times_sampled are the times of the midpoints of scanner frames, all times_sampled > 0.
            %  @return q1 has the shape of times_sampled.
            
            persistent times % for performance
            if isempty(q)
                times = [];
                q1 = [];
                return
            end
            if isempty(times)
                times = zeros(1, length(times_sampled)+1);
                for it = 2:length(times)
                    % times of midpoints of scanner frames
                    times(it) = times_sampled(it-1) + (times_sampled(it-1) - times(it-1));
                end
            end
            
            q1 = zeros(size(times_sampled));
            Nts = length(times_sampled);
            Nq = length(q);
            for it = 1:Nts-1
                indices = floor(times(it):times(it+1)) + 1;
                q1(it) = trapz(q(indices)) / (times(it+1) - times(it));
            end
            indices = floor(times(Nts):Nq-1) + 1;
            q1(Nts) = trapz(q(indices)) / (Nq - 1 - times(Nts));
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_
        data_ % ancillary value data used by model
        input_func_kit_
        parc_kit_        
        representation_kit_
        scanner_kit_
        tracer_kit_

        artery_interpolated_ % see also mixTacAif()
        bids_med_
        datetimePeak_ % see also mixTacAif()
        Dt_ % see also mixTacAif()
        input_func_ 
        measurement_ % see also mixTacAif()
        model_tags_
        parc_
        product_
        solver_ 
        t0_ % see also mixTacAif()
        tauObs_
        times_sampled_ % see also mixTacAif()
        timeCliff_
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.input_func_kit_)
                that.input_func_kit_ = copy(this.input_func_kit_); end
            if ~isempty(this.parc_kit_)
                that.parc_kit_ = copy(this.parc_kit_); end
            if ~isempty(this.representation_kit_)
                that.representation_kit_ = copy(this.representation_kit_); end
            if ~isempty(this.scanner_kit_)
                that.scanner_kit_ = copy(this.scanner_kit_); end
            if ~isempty(this.tracer_kit_)
                that.tracer_kit_ = copy(this.tracer_kit_); end

            if ~isempty(this.bids_med_)
                that.bids_med_ = copy(this.bids_med_); end
            if ~isempty(this.input_func_)
                that.input_func_ = copy(this.input_func_); end
            if ~isempty(this.parc_)
                that.parc_ = copy(this.parc_); end
            if ~isempty(this.product_)
                that.product_ = copy(this.product_); end
        end
        function this = Model(opts)
            arguments
                opts.bids_kit = [] % prototype
                opts.tracer_kit = [] % prototype
                opts.scanner_kit = [] % singleton
                opts.input_func_kit = [] % singleton
                opts.representation_kit = [] % mlkinetics.RepresentationKit {mustBeNonempty} % prototype
                opts.parc_kit = [] % mlkinetics.ParcKit {mustBeNonempty} % prototype
                opts.data struct = struct()
                opts.model_tags {mustBeText}
            end
            copts = namedargs2cell(opts);
            this.initialize(copts{:}); % for abstract factories (kits)

            if ~any(contains(opts.model_tags, "idif", IgnoreCase=true))
                [this.measurement_,this.times_sampled_,this.t0_,this.artery_interpolated_] = this.mixTacAif();
                this.set_artery_interpolated(this.artery_interpolated_);
            end
        end
    end

    %% HIDDEN

    methods (Hidden)
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
