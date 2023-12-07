classdef (Abstract) TCModel < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 11-Oct-2023 01:33:12 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Abstract, Constant)
        ks_names
    end

    methods (Abstract)
        sampled(this)
    end

    properties
        Data
        LENK
        map
    end

    properties (Dependent)
        raichleks_ic
        martinv1_ic
    end

    methods %% GET, SET
        function g = get.raichleks_ic(this)
            if isfield(this.data, "raichleks_ic")
                g = this.data.raichleks_ic;
                return
            end
            if isfield(this.data, "cbf_ic")
                g = this.data.cbf_ic;
                g = mlkinetics.OxyMetabConversion.f1ToCbf(g);
                return
            end
            g = [];
        end
        function g = get.martinv1_ic(this)
            if isfield(this.data, "martinv1_ic")
                g = this.data.martinv1_ic;
                return
            end
            if isfield(this.data, "cbv_ic")
                g = this.data.cbv_ic;
                g = mlkinetics.OxyMetabConversion.cbvToV1(g);
                return
            end
            g = [];
        end
    end

    methods
        function soln = build_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.                                

            uindex = this.unique_indices;
            Nx = numel(uindex);

            meas_ic = mlfourd.ImagingContext2(this.measurement_);
            meas_ic = this.reshape_to_parc(meas_ic);
            meas_img = meas_ic.imagingFormat.img;

            ks_mat_ = zeros([Nx this.LENK+1], 'single');
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve model and insert solutions into ks
                this.build_model(measurement = asrow(meas_img(idx, :)));
                this.solver_ = this.solver_.solve(@mlkinetics.TCModel.loss_function);
                ks_mat_(idx, :) = [asrow(this.solver_.product.ks), this.solver_.loss];

                if idx < 10
                    fprintf("%s, idx->%i, uindex->%i:", stackstr(), idx, uindex(idx))
                    toc
                end

                if any(uindex(idx) == this.indicesToCheck)
                    h = this.solver_.plot(tag="parc->"+uindex(idx));
                    saveFigure2(h, ...
                        this.product.fqfp + "_" + stackstr() + "_uindex" + uindex(idx), ...
                        closeFigure=true);
                end                  
            end

            ks_mat_ = single(ks_mat_);
            soln = this.product.selectImagingTool(img=ks_mat_);
            soln = this.reshape_from_parc(soln);
            soln.fileprefix = strrep(this.product.fileprefix, "_pet", "_ks");
            this.product_ = soln;            
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function this = TCModel(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
