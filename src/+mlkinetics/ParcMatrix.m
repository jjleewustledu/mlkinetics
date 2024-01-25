classdef (Sealed) ParcMatrix < handle & mlkinetics.Parc
    %% line1
    %  line2
    %  
    %  Created 14-Dec-2023 00:48:39 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        Nx
        unique_indices
        select_vec
    end

    methods
        function this = ParcMatrix(varargin)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
