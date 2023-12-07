classdef Martin1987Model < handle & mlkinetics.QuadraticModel
    %% line1
    %  line2
    %  
    %  Created 02-Aug-2023 16:23:14 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
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
        function [cbv_soln,v1_soln] = build_solution(this, varargin)

            % check dynamic imaging

            % check & adjust input functions, esp. their timings and timing boundaries, 
            % to match dynamic imaging 

            obsPet = this.obsFromTac(this.measurement_, t0=this.t0, tF=this.tF);
            integralAif = trapz(this.artery_interpolated_(this.t0+1:this.tF+1));
            c1 = mlkinetics.OxyMetabConversion.RATIO_SMALL_LARGE_HCT;
            c2 = mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
            v1_img = obsPet/(c1*c2*integralAif);
            v1_img(v1_img < 0) = 0;
            v1_img(v1_img > 1) = 1;
            cbv_img = mlkinetics.OxyMetabConversion.v1ToCbv(v1_img);
            
            cbv_soln = copy(this.co_ic.imagingFormat);
            cbv_soln.img = single(cbv_img);
            cbv_soln.fileprefix = strrep(this.co_ic.fileprefix, "_pet", "_cbv");
            cbv_soln = mlfourd.ImagingContext2(cbv_soln);
            this.product_ = cbv_soln; % fullfills mlkinetics.Model's builder design pattern
        end
        function ks_ = ks(this, varargin)
            %% ks == v1, to facilitate overloading

            ks_ = this.product;
        end 
        function t = tauObs(~)
            t = 240;
        end
        function t = timeStar(~)
            t = 60; % sec, per Martin's 1987 paper
        end
        function v1_ = v1(this)
            v1_ = this.product;
        end 
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Martin1987Model(varargin{:});
        end
    end

    %% PROTECTED

    properties (Access = protected)
        co_ic_
    end

    methods (Access = protected)
        function this = Martin1987Model(varargin)
            this = this@mlkinetics.QuadraticModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
