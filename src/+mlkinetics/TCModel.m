classdef TCModel < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 11-Oct-2023 01:33:12 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        LENK
        mgdL_to_mmolL

        artery_interpolated
        map
        times_sampled
    end

    properties (Dependent)
        bids_med
        parc
        trc_ic % activityDensity from ScannerKit
    end

    methods %% GET, SET
        function g = get.bids_med(this)
            if ~isempty(this.bids_med_)
                g = this.bids_med_;
                return
            end

            this.bids_med_ = this.bids_kit_.make_bids_med();
            g = this.bids_med_;
        end
        function g = get.parc(this)
            if ~isempty(this.parc_)
                g = this.parc_;
                return
            end

            this.parc_ = this.parc_kit_.make_parc();
            g = this.parc_;
        end
        function g = get.trc_ic(this)
            if ~isempty(this.trc_ic_)
                g = copy(this.trc_ic_);
                return
            end

            this.trc_ic_ = this.scanner_kit_.do_make_activity_density(decayCorrected=true);
            g = copy(this.trc_ic_);
        end

        function this = set_times_sampled(this, s)
            if isempty(s)
                return
            end
            this.times_sampled = s;
        end
        function this = set_artery_interpolated(this, s)
            if isempty(s)
                return
            end
            % artery_interpolated may be shorter than scanner times_sampled
            assert(~isempty(this.times_sampled))
            tBuffer = 0;
            if length(s) ~= floor(this.times_sampled(end)) + tBuffer + 1
                this.artery_interpolated = ...
                    interp1(-tBuffer:(length(s)-tBuffer-1), s, -tBuffer:this.times_sampled(end), ...
                    'linear', 0);
                return
            end
            this.artery_interpolated = s;
        end
    end

    methods
    end

    %% PROTECTED

    properties (Access = protected)
        bids_med_
        parc_
        solver_
        trc_ic_
    end

    methods (Access = protected)
        function this = TCModel(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
