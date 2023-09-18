classdef HplcMetabKit < handle & mlkinetics.KineticsKit
    %% line1
    %  line2
    %  
    %  Created 26-Apr-2023 19:19:05 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function this = HplcMetabKit(varargin)
            %% HPLCMETABKIT 
            %  Args:
            %      arg1 (its_class): Description of arg1.
            
            this = this@mlkinetics.KineticsKit(varargin{:});
            
            ip = inputParser;
            addParameter(ip, "arg1", [], @(x) true)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
