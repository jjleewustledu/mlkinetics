classdef Huang1980Model < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 13-Jun-2023 22:30:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
    end

    methods %% GET
    end

    methods
        function sol = make_solution(this)
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Huang1980Model(varargin{:});
        end
    end

    %% PROTECTED

    properties (Access = protected)
    end

    methods (Access = protected)
        function this = Huang1980Model(varargin)
            this = this@mlkinetics.Model(varargin{:});     
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
