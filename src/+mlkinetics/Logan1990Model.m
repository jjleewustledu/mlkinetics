classdef Logan1990Model < handle & mlsystem.IHandle
    %% is a concrete factory from a design pattern providing an interface for PRGA (Logan 1990).
    %  It is a singleton (cf. GoF pg. 90).
    %  It provides interfaces for varieties of radiotracer data, models, and analysis choices.
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/),
    %  tracers, scanners, input function methods, kinetic models, inference methods, and parcellations.  
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.ScannerKit, 
    %  mlkinetics.TracerKit, mlkinetics.ModelKit, mlkinetics.InferenceKit, mlkinetics.InputFunctionKit, 
    %  mlkinetics.ParcellationKit.
    %
    %  Created 26-Apr-2023 19:20:08 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Static)
        function this = instance(opts)
            this = mlkinetics.Logan1990Kit(opts);
            
            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlkinetics.Logan1990Kit(opts);
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.opts = opts;
            % end
        end  
    end

    %% PRIVATE

    methods (Access = private)
        function this = Logan1990Model(varargin)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
