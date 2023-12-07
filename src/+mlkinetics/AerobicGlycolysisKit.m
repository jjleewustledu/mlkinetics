classdef AerobicGlycolysisKit < handle & mlkinetics.KineticsKit 
    %% is a concrete factory from a design pattern providing an interface for tracer kinetics.
    %  It is a singleton (cf. GoF pg. 90).
    %  It provides interfaces for varieties of radiotracer data, models, and analysis choices.
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/),
    %  tracers, scanners, input function methods, kinetic models, inference methods, and parcellations.  
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.ScannerKit, 
    %  mlkinetics.TracerKit, mlkinetics.ModelKit, mlkinetics.InputFunctionKit, mlkinetics.ParcellationKit.
    %
    %  Created 09-Jun-2022 14:28:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods (Static)
        function this = instance(opts)
            this = mlkinetics.AerobicGlycolysisKit(opts);

            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlkinetics.AerobicGlycolysisKit(opts);
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.opts = opts;
            % end
        end  
    end

    %% PRIVATE

    methods (Access = private)
        function this = AerobicGlycolysisKit(varargin)
            this = this@mlkinetics.KineticsKit(varargin{:});
        end
    end

    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
