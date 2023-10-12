classdef Representation < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:04:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Static)
        function this = create()
            this = mlkinetics.Representation();
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = Representation()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
