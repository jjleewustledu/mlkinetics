classdef OxyMetabConversion < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 03-Aug-2023 11:38:27 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.

    properties (Constant)
        BLOOD_DENSITY = 1.06         % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05         % Torack et al., 1976, g/mL        
        PLASMA_DENSITY = 1.03
        DENSITY_BLOOD = 1.06
        DENSITY_BRAIN = 1.05
        DENSITY_PLASMA = 1.03
        LAMBDA = 0.95                % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        RATIO_SMALL_LARGE_HCT = 0.85 % Grubb, et al., 1978
        RBC_FACTOR = 0.766           % per Tom Videen, metproc.inc, line 193  
    end

    methods
        function K1 = ks_to_K1(this, ks)
            %  Args: k1 ImagingContext2 ~ 1/s.
            %  Return K1 ImagingContext2 ~ blood_volume*k1 ~ mL/hg/min.
            
            assert(isa(ks, 'mlfourd.ImagingContext2'))

            ifc_ = ks.imagingFormat;
            if 4 == ndims(ifc_)
                ifc_.img = ifc_.img(:,:,:,1);
            end

            k1_ = mlfourd.ImagingContext2(ifc_); % 1/s
            K1 = k1_ .* (60*100/this.DENSITY_BRAIN); % mL/hg/min
            K1.fileprefix = strrep(ks.fileprefix, 'ks', 'K1');
        end
        function cbv = v1_to_cbv(this, v1)
            %  Args: v1 ImagingContext2.
            %  Return cbv ImagingContext2 ~ blood volume ~ mL/hg.
            
            assert(isa(v1, 'mlfourd.ImagingContext2'))

            ifc_ = v1.imagingFormat;
            if 4 == ndims(ifc_)
                ifc_.img = ifc_.img(:,:,:,1);
            end

            v1_ = mlfourd.ImagingContext2(ifc_);
            cbv = v1_ .* (100/this.DENSITY_BRAIN);
            cbv.fileprefix = strrep(v1.fileprefix, 'v1', 'cbv');
        end
    end

    methods (Static)
        function this = create()
            this = mlkinetics.OxyMetabConversion();
        end

        function v1   = cbvToV1(cbv)
            % mL/hg -> unit-less
            % numeric or mlfourd.ImagingContext2
            v1 = cbv .* mlkinetics.OxyMetabConversion.DENSITY_BRAIN/100;
        end
        function f1   = cbfToF1(cbf)
            % mL/min/hg -> 1/s
            % numeric or mlfourd.ImagingContext2
            f1 = cbf .* mlkinetics.OxyMetabConversion.DENSITY_BRAIN/6000;
        end
        function cbf  = f1ToCbf(f1)
            % 1/s -> mL/min/hg
            % numeric or mlfourd.ImagingContext2
            cbf = f1 .* 6000/mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
        end
        function mLmL = lambdaToUnitless(mLg)
            % mL/g -> mL/mL  
            % numeric or mlfourd.ImagingContext2          
            mLmL = mLg .* mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
        end
        function mLg  = unitlessToLambda(mLmL)
            % mL/mL -> mL/g
            % numeric or mlfourd.ImagingContext2
            mLg = mLmL ./ mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
        end
        function cbv  = v1ToCbv(v1)
            % unit-less -> mL/hg  
            % numeric or mlfourd.ImagingContext2          
            cbv = v1 .* 100/mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
        end
    end

    %% PRIVATE
    
    methods (Access = private)
        function this = OxyMetabConversion()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
