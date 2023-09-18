classdef (Sealed) OxyMetabKit < handle & mlkinetics.KineticsKit
    %% is a concrete factory from a design pattern providing an interface for tracer kinetics.
    %  It is a singleton (cf. GoF pg. 90).
    %  It is an extensible factory making using of the factory method pattern (cf. GoF pp. 90-91, 107). 
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/), 
    %  tracers, scanners, input functions, parcellations, and models.   
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.TracerKit, 
    %  mlkinetics.ScannerKit, mlkinetics.InputFunctionKit, mlkinetics.ParcKit, and mlkinetics.ModelKit.
    %
    %  See also http://www.turkupetcentre.net/petanalysis/analysis_o2_brain.html for varieties of models.
    %
    %  Created 26-Apr-2023 19:18:51 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods

        %% make related products, with specialty relationships specified by the ctor

        function agi = do_make_agi(this, varargin)
            %% AGI := cmrglc - cmro2/6
            cmro2 = this.do_make_R();
            glcMetabKit = mlkinetics.GlcMetabKit.instance();
            cmrglc = glcMetabKit.do_make_R();
            agi = nan;
        end
        function ogi = do_make_ogi(this, varargin)
            %% OGI := cmro2./cmrglc
            cmro2 = this.do_make_R();
            glcMetabKit = mlkinetics.GlcMetabKit.instance();
            cmrglc = glcMetabKit.do_make_R();
            ogi = nan;
        end
        
        function cbv = do_make_cbv(this, varargin)
            %% cbv ~ blood volume ~ mL/hg
            mdl = this.model_kit_.make_model(varargin{:});
            if isa(mdl, "mlkinetics.QuadraticModel")
                cbv = mdl.make_solution();
                return
            end
            v1 = this.do_make_v1(varargin{:});
            cbv = this.conversion_.v1_to_cbv(v1);
        end
        function cbf = do_make_cbf(this, varargin)
            %% cbf ~ blood flow ~ mL/min/hg
            mdl = this.model_kit_.make_model(varargin{:});
            if isa(mdl, "mlkinetics.QuadraticModel")
                cbf = mdl.make_solution();
                return
            end
            cbf = this.do_make_K1(varargin{:});
        end
        function oef = do_make_oef(~, varargin)
            %% oef ~ oxygen extraction fraction \in [0,1]
            mdl = this.model_kit_.make_model(varargin{:});
            if isa(mdl, "mlkinetics.QuadraticModel")
                oef = mdl.make_solution();
                return
            end
            oef = this.do_make_E(varargin{:});
        end
        function cmro2 = do_make_cmro2(~, varargin)
            %% cmro2 ~ metabolic rate for oxygen ~ \mu mol/min/hg
            mdl = this.model_kit_.make_model(varargin{:});
            if isa(mdl, "mlkinetics.QuadraticModel")
                cmro2 = mdl.make_solution();
                return
            end
            cmro2 = this.do_make_R(varargin{:});            
        end
        function E = do_make_E(this, varargin)
            %% E ~ extraction fraction \in [0, 1]
            E = nan;
        end
        function R = do_make_R(this, varargin)
            %% R ~ cerebral metabolic rate ~ \mu mol/min/hg
            R = nan;
        end

        function v1 = do_make_v1(this, varargin)
            %% ImagingContext2 v1 ~ blood volume \in [0,1]
            v1 = this.model_kit_.make_solution(model_tags="martin1987");
        end
        function K1 = do_make_K1(~, varargin)
            %% K1 ~ V1*k1 ~ mL/min/hg
            ks = this.do_make_ks(varargin{:});
            K1 = this.conversion_.ks_to_K1(ks);
        end
        function ks = do_make_ks(this, varargin)
            %% ks ~ kinetic rates ~ 1/s
            ks = nan;
        end
        function Vt = do_make_Vt(this, varargin)
            %% Vt ~ volume of distribution
            Vt = nan;
        end
        function BP = do_make_BP(this, varargin)
            %% BP ~ binding potential
            BP = nan;
        end
        function ga = do_make_ga(this, varargin)
            %% ga ~ graphical analysis results ~ struct
            ga = struct([]);
        end
    end

    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlkinetics.OxyMetabKit();
                this.install_kinetics(varargin{:});
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.install_kinetics(varargin{:});
            end
        end  
    end

    %% PRIVATE

    properties (Access = private)
        conversion_
    end

    methods (Access = private)
        function this = OxyMetabKit()
            this.conversion_ = mlkinetics.OxyMetabConversion.create();
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
