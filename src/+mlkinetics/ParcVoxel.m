classdef (Sealed) ParcVoxel < handle & mlkinetics.Parc
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:25:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function a = make_activity(this)
            a = [];
        end
        function a = make_activity_density(this)
            a = [];
        end
        function ic = make_imaging(this)
            ic = mlfourd.ImagingContext2();
        end

        function ic = reshape_from_parc(~, ic)
        end
        function ic = reshape_to_parc(~, ic)
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.ParcVoxel(varargin{:});
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = ParcVoxel(varargin)
            this = this@mlkinetics.Parc(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
