classdef (Abstract) KineticModelKit < handle
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 11:21:43 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods
        function this = KineticModelKit(varargin)
            %% KINETICMODELKIT 
            %  Args:
            %      arg1 (its_class): Description of arg1.
            
            ip = inputParser;
            addParameter(ip, "arg1", [], @(x) false)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
