classdef QuadraticMartin1987Model < handle & mlkinetics.QuadraticModel
    %% line1
    %  line2
    %  
    %  Created 02-Aug-2023 23:43:13 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        co_ic
    end

    methods %% GET
        function g = get.co_ic(this)
            if ~isempty(this.co_ic_)
                g = copy(this.co_ic_);
                return
            end
            this.co_ic_ = this.scanner_kit_.do_make_activity_density();
            g = copy(this.co_ic_);
        end
    end

    methods
        function soln = make_solution(this)

            % check dynamic imaging

            % check & adjust input functions, esp. their timings and timing boundaries, 
            % to match dynamic imaging 

            obsPet = this.obsFromTac(this.measurement_, t0=this.t0_, tF=this.tF_);
            integralAif = trapz(this.artery_interpolated_(this.t0_+1:this.tF_+1));
            c1 = mlkinetics.OxyMetabConversion.RATIO_SMALL_LARGE_HCT;
            c2 = mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
            img = obsPet/(c1*c2*integralAif);
            img = mlkinetics.OxyMetabConversion.v1ToCbv(img);
            
            soln = copy(this.co_ic.imagingFormat);
            soln.img = single(img);
            soln.fileprefix = strrep(strrep(this.co_ic.fileprefix, "_trc-co", "_cbv"), "_tr-oc", "_cbv");
            soln = mlfourd.ImagingContext2(soln);
            this.product_ = soln; % fullfills mlkinetics.Model's builder design pattern
        end

        %% UTILITIES

        function t = tauObs(~)
            t = 240;
        end
        function t = timeStar(~)
            t = 60; % sec, per Martin's 1987 paper
        end
    end

    methods (Static)
        function this = create(varargin)

            this = mlkinetics.QuadraticMartin1987Model(varargin{:});
            
            [this.measurement_,this.timesMid_,t0,this.artery_interpolated_] = this.mixTacAif( ...
                this.scanner_kit_, ...
                scanner_kit=this.scanner_kit_, ...
                input_func_kit=this.input_func_kit_, ...
                roi=this.dlicv_ic);
            this.t0_ = t0 + this.timeStar;
            this.tF_ = min(t0 + this.tauObs, this.timeCliff);
        end
    end

    %% PRIVATE

    properties (Access = private)
        co_ic_
    end

    methods (Access = private)
        function this = QuadraticMartin1987Model(varargin)
            this = this@mlkinetics.QuadraticModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
