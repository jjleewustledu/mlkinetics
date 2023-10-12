classdef TwoTCMKit < handle & mlkinetics.KineticsKit
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
    %  Created 06-Oct-2023 00:16:59 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods

        %% make related products, with specialty relationships specified by the ctor
        
        function Ri = do_make_Ri(this, opts)
            %% Ri ~ cerebral metabolic rate ~ \mu mol/min/hg
            
            arguments
                this mlkinetics.TwoTCMKit
                opts.ks_ic mlfourd.ImagingContext2
                opts.content double
            end

            Ri = [];
            Ri.filepath = E.filepath;
            Ri.fileprefix = "";
        end

        function v1 = do_make_v1(this, varargin)
            %% ImagingContext2 v1 ~ blood volume \in [0,1]
            v1 = this.model_kit_.make_solution(model_tags="");
        end
        function K1 = do_make_K1(~, varargin)
            %% K1 ~ V1*k1 ~ mL/min/hg
            ks = this.do_make_ks(varargin{:});
            K1 = this.conversion_.ks_to_K1(ks);
        end
        function ks = do_make_ks(this, opts)
            %% ks ~ kinetic rates ~ 1/s

            arguments
                this mlkinetics.TwoTCMKit
                opts.data = [];
            end

            this.model_kit_.make_model( ...
                data=opts.data, ...
                model_tags="2tcm-simulanneal");
            ks = this.model_kit_.make_solution();
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
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlkinetics.TwoTCMKit();
                this.install_kinetics(varargin{:});
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.install_kinetics(varargin{:});
            end
        end  
    end

    %% PRIVATE

    methods (Access = private)
        function this = TwoTCMKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
