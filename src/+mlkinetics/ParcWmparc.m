classdef (Sealed) ParcWmparc < handle & mlkinetics.Parc
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:45:16 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        Nx
        unique_indices
        select_vec
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

            ifc_ = this.select_ic_.imagingFormat;
            this.unique_indices_ = unique(ifc_.img(ifc_.img > 0));
            g = this.unique_indices_;
        end
        function g = get.select_vec(this)
            if ~isempty(this.select_vec_)
                g = this.select_vec_;
                return
            end

            ifc_ = this.select_ic_.imagingFormat;
            numel_ = numel(this.select_ic_);
            this.select_vec_ = reshape(ifc_.img, [numel_, 1]);
            g = this.select_vec_;
        end
    end

    methods
        function idx = indicesToCheck(~)
            if isdeployed() || ~isempty(getenv('NOPLOT'))
                idx = 0;
                return
            end
            
            % limited indices for checking
            % 1 -> left cerebral exterior
            % 7 -> left cerebellum wm
            % 8 -> left cerebellum cortex
            % 10 -> left thalamus
            % 11 -> left caudate
            % 12 -> left putamen
            % 13 -> left pallidum
            % 16 -> brainstem
            % 17 -> left hippo
            % 18 -> left amygdala
            % 19 -> left insula
            % 20 -> left operculum
            % 1025 -> ctx lh precuneus
            % 2025 -> ctx rh precuneus
            % 3025 -> wm lh precuneus
            % 4025 -> wm rh precuneus
            % 5001 -> left unsegmented wm
            % 5002 -> right unsegmented wm

            idx = [1 7:13 16:20 24 26:28 1025 2000 3000 4000 5001 5002 6000];
        end
        function ic = reshape_from_parc(this, ic1)
            %% ndims(ic1) == 2 => ndims(ic) == 4, inverse of reshape_to_parc

            assert(ndims(ic1) == 2) %#ok<ISMAT
            ifc1 = ic1.imagingFormat;

            sz = asrow(size(this.mlsurfer_wmarc_.wmparc));
            Nt = size(ifc1, 2);
            ifc_mat = ifc1.img;
            img_ = zeros([prod(sz), Nt]);
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                Nselect = sum(idx_select);
                img_(idx_select, :) = repmat(ifc_mat(idx, :), [Nselect, 1]);
            end
            ifc1.img = reshape(img_, [sz(1), sz(2), sz(3), Nt]);
            ifc1.img = squeeze(ifc1.img);
            if contains(ifc1.fileprefix, "reshape_to_parc")
                ifc1.fileprefix = strrep(ifc1.fileprefix, "reshape_to_parc", "reshape_from_parc");
            else
                ifc1.fileprefix = ifc1.fileprefix + "_" + stackstr();
            end            
            ic = mlfourd.ImagingContext2(ifc1);
        end
        function ic1 = reshape_to_parc(this, ic)
            if ndims(ic) == 4
                ic1 = this.reshape_to_parc_4d(ic);
                return
            end
            if ndims(ic) == 3
                ic1 = this.reshape_to_parc_3d(ic);
                return
            end
            error("mlkinetic:RuntimeError", stackstr())
        end
        function ic1 = reshape_to_parc_3d(this, ic)
            %% ndims(ic) == 3 => ndims(ic1) == 2

            assert(ndims(ic) == 3)
            ifc = ic.imagingFormat;

            sz = size(ifc);
            Nt = 1;
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), Nt]);
            img_ = zeros(this.Nx, Nt);
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                img_(idx) = mean(ifc_mat(idx_select), 1, "omitnan");
            end
            ifc.img = single(img_);
            ifc.fileprefix = ifc.fileprefix + "_" + stackstr();
            ic1 = mlfourd.ImagingContext2(ifc);
        end
        function ic1 = reshape_to_parc_4d(this, ic)
            %% ndims(ic) == 4 => ndims(ic1) == 2

            assert(ndims(ic) == 4)            
            ifc = ic.imagingFormat;

            sz = size(ifc);
            Nt = size(ifc, 4);
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), Nt]);
            img_ = zeros(this.Nx, Nt);
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                img_(idx, :) = mean(ifc_mat(idx_select,:), 1, "omitnan");
            end
            ifc.img = single(img_);
            ifc.fileprefix = ifc.fileprefix + "_" + stackstr();
            ic1 = mlfourd.ImagingContext2(ifc);
        end
    end
    
    methods (Static)
        function this = create(varargin)
            this = mlkinetics.ParcWmparc(varargin{:});

            med = this.bids_kit_.make_bids_med();
            this.mlsurfer_wmarc_ = mlsurfer.Wmparc.createCoregisteredFromBids( ...
                med.bids, med.imagingContext);

            if contains(this.parc_tags_, "wmparc-wmparc")                
                this.select_ic_ = this.mlsurfer_wmarc_.wmparc();
                return
            end
            if contains(this.parc_tags_, "select-all")                
                this.select_ic_ = this.mlsurfer_wmarc_.select_all();
                return
            end
            if contains(this.parc_tags_, "select-cortex")                
                this.select_ic_ = this.mlsurfer_wmarc_.select_cortex();
                return
            end
            if contains(this.parc_tags_, "select-gray")
                this.select_ic_ = this.mlsurfer_wmarc_.select_gray();
                return
            end
            if contains(this.parc_tags_, "select-white")
                this.select_ic_ = this.mlsurfer_wmarc_.select_white();
                return
            end
            if contains(this.parc_tags_, "select-subcortex")
                this.select_ic_ = this.mlsurfer_wmarc_.select_subcortex();
                return
            end
            if contains(this.parc_tags_, "select-cerebellum")
                this.select_ic_ = this.mlsurfer_wmarc_.select_cerebellum();
                return
            end
            if contains(this.parc_tags_, "select-cereb-gray")
                this.select_ic_ = this.mlsurfer_wmarc_.select_cereb_gray();
                return
            end
            if contains(this.parc_tags_, "select-cereb-white")
                this.select_ic_ = this.mlsurfer_wmarc_.select_cereb_white();
                return
            end
            if contains(this.parc_tags_, "select-csf")
                this.select_ic_ = this.mlsurfer_wmarc_.select_csf();
                return
            end
        end
    end

    %% PRIVATE

    properties (Access = private)
        Nx_
        select_ic_
        select_vec_
        unique_indices_
        mlsurfer_wmarc_
    end

    methods
        function this = ParcWmparc(varargin)
            this = this@mlkinetics.Parc(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
