classdef Logan1996Model < handle & mlsystem.IHandle
    %% is a concrete factory from a design pattern providing an interface for RTGA (Logan 1996).
    %  It is a singleton (cf. GoF pg. 90).
    %  It provides interfaces for varieties of radiotracer data, models, and analysis choices.
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/),
    %  tracers, scanners, input function methods, kinetic models, inference methods, and parcellations.  
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.ScannerKit, 
    %  mlkinetics.TracerKit, mlkinetics.ModelKit, mlkinetics.InferenceKit, mlkinetics.InputFunctionKit, 
    %  mlkinetics.ParcellationKit.
    %
    %  Created 26-Apr-2023 19:20:13 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Static)
        function this = instance(opts)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlkinetics.Logan1996Kit(opts);
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.opts = opts;
            end
        end  
    end

    %% PRIVATE

    methods (Access = private)
        function this = Logan1996Model(varargin)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
