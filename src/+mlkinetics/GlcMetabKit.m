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
    
    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlkinetics.GlcMetabKit();
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
        function this = GlcMetabKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
