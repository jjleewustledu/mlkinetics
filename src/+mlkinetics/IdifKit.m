classdef IdifKit < handle & mlkinetics.InputFuncKit
    %% Image-derived input function kit:  builds using ScannerKit, TracerKit
    %  
    %  Created 07-Sep-2023 15:18:50 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        decayCorrected 
    end

    methods %% GET
        function g = get.decayCorrected(this)
            assert(~isempty(this.input_func_ic_))
            g = this.decayCorrected_;
        end
    end

    methods
        function decayCorrect(this)
            if ~this.decayCorrected_
                assert(~isempty(this.input_func_ic_))
                fp = this.input_func_ic_.fileprefix;
                this.input_func_ic_ = this.input_func_ic_.* ...
                    2.^( this.timesMid/this.halflife);
                this.input_func_ic_.fileprefix = ...
                    mlpipeline.Bids.adjust_fileprefix(fp, post_proc="decayCorrected");
                this.decayCorrected_ = true;
            end
        end
        function decayUncorrect(this)
            if this.decayCorrected_
                assert(~isempty(this.input_func_ic_))
                fp = this.input_func_ic_.fileprefix;
                this.input_func_ic_ = this.input_func_ic_.* ...
                    2.^(-this.timesMid/this.halflife);
                this.input_func_ic_.fileprefix = ...
                    mlpipeline.Bids.adjust_fileprefix(fp, post_proc="decayUnorrected");
                this.decayCorrected_ = false;
            end
        end

        function this = IdifKit(varargin)
            this = this@mlkinetics.InputFuncKit(varargin{:});
        end
    end

    %% PROTECTED

    properties (Access = protected)
        decayCorrected_
    end

    methods (Access = protected)
        function hl = halflife(this)
            r = this.tracer_kit_.make_radionuclides();
            hl = r.halflife;
        end
        function t = timesMid(this)
            j = this.input_func_ic_.json_metadata;
            t = asrow(j.timesMid);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
