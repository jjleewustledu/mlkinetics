classdef (Sealed) GlcMetabKit < handle & mlkinetics.KineticsKit
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
    %  Created 26-Apr-2023 19:17:42 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods

        %% make related products, with specialty relationships specified by the ctor

        function agi = do_make_agi(this, varargin)
            %% AGI := cmrglc - cmro2/6
            oxyMetabKit = mlkinetics.GlcMetabKit.instance();
            cmro2 = oxyMetabKit.do_make_cmro2();
            cmrglc = this.do_make_cmrglc();
            agi = nan;
        end
        function ogi = do_make_ogi(this, varargin)
            %% OGI := cmro2./cmrglc
            oxyMetabKit = mlkinetics.GlcMetabKit.instance();
            cmro2 = oxyMetabKit.do_make_cmro2();
            cmrglc = this.do_make_glc();
            ogi = nan;
        end
        
        function cmrglc = do_make_cmrglc(this, opts)
            %% cmrglc ~ cerebral metabolic rate for glucose ~ \mu mol/min/hg

            arguments
                this mlkinetics.GlcMetabKit
                opts.cbv_ic mlfourd.ImagingContext2
                opts.content double = mlkinetics.GlcMetabConversion.NOMINAL_GLC_CONTENT
            end

            data = struct("cbv_ic", opts.cbv_ic, "content", opts.content);
            this.model_kit_.make_model( ...
                data=data, ...
                model_tags="huang1980-simulanneal");
            cmrglc = this.model_kit_.make_solution();
        end
        function Ri = do_make_Ri(this, varargin)
            %% Ri ~ cerebral metabolic rate ~ \mu mol/min/hg
            
            Ri = this.do_make_cmrglc(varargin{:});
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
    end

    methods (Static)
        function this = instance(varargin)
            this = mlkinetics.GlcMetabKit();
            this.install_kinetics(varargin{:});
            
            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlkinetics.GlcMetabKit();
            %     this.install_kinetics(varargin{:});
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.install_kinetics(varargin{:});
            % end
        end  
    end

    %% PRIVATE

    methods (Access = private)
        function this = GlcMetabKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
