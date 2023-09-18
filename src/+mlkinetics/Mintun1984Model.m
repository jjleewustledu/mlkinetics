classdef Mintun1984Model < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 09-Sep-2023 20:34:07 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    


    methods (Static)
        function this = create(varargin)

            this = mlkinetics.Mintun1984Model(varargin{:});
            
            [this.measurement_,this.timesMid_,t0,this.artery_interpolated_] = this.scanner_kit_.mixTacAif( ...
                this.scanner_kit_, ...
                scanner_kit=this.scanner_kit_, ...
                input_func_kit=this.input_func_kit_, ...
                roi=this.dlicv_ic);
            this.t0_ = t0;
            this.tF_ = min(t0 + this.tauObs, this.timeCliff);

            assert(isfield(this.data_, "cbf_ic"), ...
                "%s: data_ is missing cbf_ic", stackstr())
            assert(isfield(this.data_, "cbv_ic"), ...
                "%s: data_ is missing cbv_ic", stackstr())
            this.cbf_ic_ = this.data_.cbf_ic;
            this.cbv_ic_ = this.data_.cbv_ic;

            % apply Mintun's kinetics assumptions
            this = metabolize(this);
        end
    end

    %% PRIVATE

    properties (Access=private)
        oo_ic_

        artery_oxygen_
        artery_water_metab_
        cbf_ic_
        cbv_ic_
        integral_artery_oxygen_
    end

    methods (Access=private)
        function this = Mintun1984Model(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
