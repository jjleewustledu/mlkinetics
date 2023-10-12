classdef (Abstract) Model < handle & mlsystem.IHandle
    %% The mlkinetics.Model class hierarchy loosely implements the builder design pattern (GoF, pp. 97ff.).
    %  Useful for building are the product property and method function make_solution(). 
    %  The director of the builder will be an mlkinetics.ModelKit. 
    %  
    %  Created 13-Jun-2023 22:58:44 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Abstract, Static)
        create()
    end

    methods (Abstract)
        make_solution(this)
    end

    %% Shared Implementations

    properties (Dependent)
        data % ancillary data used by model
        dlicv_ic % coregistered to dynamic PET
        input_func
        model
        product % intermediate and final products
    end

    methods %% GET
        function g = get.data(this)
            g = this.data_;
        end
        function g = get.dlicv_ic(this)
            if ~isempty(this.dlicv_ic_)
                g = copy(this.dlicv_ic_);
                return
            end
            %parc = this.parc_kit_.make_parc();
            %this.dlicv_ic_ = parc.dlicv_on_target(this.co_ic);
            med = this.bids_kit_.make_bids_med();
            this.dlicv_ic_ = med.dlicv_ic;
            if isempty(this.dlicv_ic_)
                g = this.dlicv_ic_;
            end
            g = copy(this.dlicv_ic_);
        end
        function g = get.input_func(this)
            if ~isempty(this.input_func_)
                g = this.input_func_;
                return
            end
            this.input_func_ = this.input_func_kit_.do_make_activity_density();
            g = this.input_func_;
        end
        function g = get.model(this)
            g = this;
        end
        function g = get.product(this)
            g = this.product_;
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
                opts.data struct = struct([])
                opts.model_tags = []
            end

            for f = asrow(fields(opts))
                if ~isempty(opts.(f{1}))
                    this.(strcat(f{1}, "_")) = opts.(f{1});
                end
            end
        end

        %% UTILITIES

        function [measurement,timesMid,t0,artery_interpolated,Dt,datetimePeak] = mixTacAif(this)
            %% adapts kinetic models to legacy mixture methods enumerated in mlkinetics.ScannerKit

            arguments
                this mlkinetics.Model                
            end

            switch class(this.input_func_kit_)
                case 'mlkinetics.CapracKit'
                    [measurement,timesMid,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacAif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case 'mlkinetics.TwiliteKit'
                    [measurement,timesMid,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacAif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case 'mlkinetics.IdifKit'
                    [measurement,timesMid,t0,artery_interpolated,Dt,datetimePeak] = this.scanner_kit_.mixTacIdif( ...
                        this.scanner_kit_, ...
                        scanner_kit=this.scanner_kit_, ...
                        input_func_kit=this.input_func_kit_, ...
                        roi=this.dlicv_ic);
                case 'mlkinetics.NiftiInputFuncKit'
                    ad_sk = this.scanner_kit_.do_make_activity_density();
                    measurement = ad_sk.imagingFormat.img;
                    ad_ifk = this.input_func_kit_.do_make_activity_density();
                    j = ad_ifk.json_metadata;
                    timesMid = j.timesMid;
                    t0 = 0;
                    artery = asrow(ad_ifk.imagingFormat.img);
                    tau = timesMid(end) - timesMid(end-1);
                    artery_interpolated = interp1(timesMid, artery, 0:timesMid(end)+tau/2);
                    Dt = 0;
                    [~,idxPeak] = max(artery_interpolated);
                    dev = this.scanner_kit_.do_make_device();
                    datetimePeak = dev.datetime0 + seconds(idxPeak-1);                    
                otherwise
                    error("mlkinetics:ValueError", "%s: unknown class %s", ...
                        stackstr(), class(this.input_func_kit))
            end
        end
        function t = tauObs(~)    
            %% duration of valid data ~ timeCliff - t0
            t = NaN;
        end
        function t = timeCliff(~)
            %% time at which valid AIF measurements abruptly end because of experimental conditions.
            %  timeCliff <= tF, the last time recorded in dataframes.

            t = Inf;
        end
        function t = timeStar(~)  
            %% time at which model requirements such as steady-state or linearity are met
            t = NaN;
        end
    end

    methods (Static)
        function q1 = solutionOnScannerFrames(q, times_sampled)
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
        model_tags_
        parc_kit_        
        representation_kit_
        scanner_kit_
        tracer_kit_

        artery_interpolated_
        dlicv_ic_
        input_func_ % 
        measurement_
        product_
        solver_ % 
        t0_
        timesMid_
        tF_
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
            if ~isempty(this.scanner_kit_)
                that.scanner_kit_ = copy(this.scanner_kit_); end
            if ~isempty(this.tracer_kit_)
                that.tracer_kit_ = copy(this.tracer_kit_); end
        end
        function this = Model(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty} % prototype
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty} % prototype
                opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty} % singleton
                opts.input_func_kit mlkinetics.InputFuncKit {mustBeNonempty} % singleton
                opts.representation_kit = [] % mlkinetics.RepresentationKit {mustBeNonempty} % prototype
                opts.parc_kit = [] % mlkinetics.ParcKit {mustBeNonempty} % prototype
                opts.data struct 
                opts.model_tags {mustBeText}
            end
            copts = namedargs2cell(opts);
            this.initialize(copts{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
