classdef (Sealed) WmparcParc < handle & mlkinetics.Parc
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:45:16 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        Nx
        unique_indices
        wmparc_select_vec
    end

    methods %% GET
        function g = get.Nx(this)
            g = numel(this.unique_indices);            
        end
        function g = get.unique_indices(this)
            if ~isempty(this.unique_indices_)
                g = this.unique_indices_;
                return
            end

            ifc_ = this.wmparc_select_ic_.imagingFormat;
            this.unique_indices_ = unique(ifc_.img(ifc_.img > 0));
            g = this.unique_indices_;
        end
        function g = get.wmparc_select_vec(this)
            if ~isempty(this.wmparc_select_vec_)
                g = this.wmparc_select_vec_;
                return
            end

            ifc_ = this.wmparc_select_ic_.imagingFormat;
            sz = size(this.wmparc_select_ic_);
            this.wmparc_select_vec_ = reshape(ifc_.img, [prod(sz), 1]);
            g = this.wmparc_select_vec_;
        end
    end

    methods
        function ic = reshape_from_parc(this, ic1)
            %% ndims(ic1) == 2 => ndims(ic) == 4, inverse of reshape_to_parc

        end
        function ic1 = reshape_to_parc(this, ic)
            %% ndims(ic) == 4 => ndims(ic1) == 2

            assert(ndims(ic) == 4)
            ifc = ic.imagingFormat;
            sz = size(ic);
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), sz(4)]);

            Nt = size(ifc, 4);
            img_ = zeros(this.Nx, Nt);
            for idx = 1:this.Nx
                idx_select = this.wmparc_select_vec == this.unique_indices(idx);
                img_(idx, :) = mean(ifc_mat(idx_select,:), 1, "single", "omitnan");
            end
            ifc.img = img_;
            ifc.fileprefix = ifc.fileprefix + "_" + stackstr();
            ic1 = mlfourd.ImagingContext2(ifc);
        end
    end
    
    methods (Static)
        function this = create(varargin)
            this = mlkinetics.WmparcParc(varargin{:});

            med = this.bids_kit_.make_bids_med();
            this.wmparc_ = mlsurfer.Wmparc.create(med.wmparc_on_t1w_ic);
            this.wmparc_select_ic_ = this.wmparc_.select_all(); 
        end
    end

    %% PRIVATE

    properties (Access = private)
        Nx_
        wmparc_select_ic_
        wmparc_select_vec_
        unique_indices_
        wmparc_
    end

    methods
        function this = WmparcParc(varargin)
            this = this@mlkinetics.Parc(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
