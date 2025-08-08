classdef (Sealed) ParcSchaeffer < handle & mlkinetics.Parc
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:45:16 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        Nx
        unique_indices
        select_ic
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
        function g = get.select_ic(this)
            g = this.select_ic_;
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
        function ic = reshape_from_parc(this, ic1, opts)
            %% ndims(ic1) == 2 => ndims(ic) == 4, inverse of reshape_to_parc

            arguments
                this mlkinetics.ParcSchaeffer
                ic1 mlfourd.ImagingContext2
                opts.target = []
            end

            % convenience
            if ~isa(ic1, "mlfourd.ImagingContext2")
                ic1 = mlfourd.ImagingContext2(ic1);
            end

            assert(ndims(ic1) == 2) %#ok<ISMAT
            ifc1 = ic1.imagingFormat;

            sz = asrow(size(this.mlsurfer_schaeffer_.schaeffer));
            Nt = size(ifc1, 2);
            ifc_mat = ifc1.img;
            img_ = zeros([prod(sz), Nt]);
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                Nselect = sum(idx_select);
                img_(idx_select, :) = repmat(ifc_mat(idx, :), [Nselect, 1]);
            end

            if isempty(opts.target)
                ifc11 = ifc1;
            else
                ifc11 = opts.target.imagingFormat;
            end
            ifc11.img = reshape(img_, [sz(1), sz(2), sz(3), Nt]);
            ifc11.img = squeeze(ifc11.img);
            idx_proc = strfind(ifc1.fileprefix, "_proc-");
            idx_scha = strfind(ifc1.fileprefix, "-schaeffer-schaeffer") + length('-schaeffer-schaeffer');
            c = convertStringsToChars(ifc1.fileprefix);
            ifc11.fileprefix = c(1:idx_proc-1) + "_proc-" + stackstr(use_dashes=true) + "-" + c(idx_scha+1:end);
            ic = mlfourd.ImagingContext2(ifc11);
            ic.filepath = strrep(ic1.filepath, "sourcedata", "derivatives");
        end
        function ic1 = reshape_to_parc(this, ic)

            % convenience
            if ~isa(ic, "mlfourd.ImagingContext2")
                ic = mlfourd.ImagingContext2(ic);
            end

            if ndims(ic) == 4
                ic1 = this.reshape_to_parc_4d(ic);
                ic1.filepath = strrep(ic1.filepath, "sourcedata", "derivatives");
                return
            end
            if ndims(ic) == 3
                ic1 = this.reshape_to_parc_3d(ic);
                ic1.filepath = strrep(ic1.filepath, "sourcedata", "derivatives");
                return
            end
            error("mlkinetic:RuntimeError", stackstr())
        end
        function ic1 = reshape_to_parc_fast(this, fqfn)
            %% assumes filename corresponds to 4D large NIfTI; saves results immediately

            arguments
                this mlkinetics.ParcSchaeffer
                fqfn {mustBeFile}
            end

            if ~isfile(fqfn)
                fqfn = strrep(fqfn, ".nii.gz", ".nii");
            end
            assert(isfile(fqfn))
            ifc = mlfourd.ImagingFormatContext2(fqfn);

            sz = size(ifc);
            % assert(prod(sz(1:3)) == length(this.select_vec));  % ensure that select_ic is compatible with ic
            Nt = size(ifc, 4);
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), Nt]);
            ifc.img = [];  % conserve memory
            img_ = zeros(this.Nx, Nt, "single");
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                img_(idx, :) = mean(ifc_mat(idx_select,:), 1, "omitnan");
            end
            ifc.img = single(img_);
            tags = "ParcSchaeffer-reshape-to-" + this.parc_tags;
            tags = strrep(tags, "_", "-");
            ifc.fileprefix = ifc.fileprefix + "-" + tags;
            ic1 = mlfourd.ImagingContext2(ifc);

            ic1.filepath = strrep(ic1.filepath, "sourcedata", "derivatives");
        end
        function ic1 = reshape_to_parc_3d(this, ic)
            %% ndims(ic) == 3 => ndims(ic1) == 2

            assert(ndims(ic) == 3)
            ifc = ic.imagingFormat;

            sz = size(ifc);
            % assert(prod(sz) == length(this.select_vec));  % ensure that select_ic is compatible with ic
            Nt = 1;
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), Nt]);
            ifc.img = [];  % conserve memory
            img_ = zeros(this.Nx, Nt);
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                img_(idx) = mean(ifc_mat(idx_select), 1, "omitnan");
            end
            ifc.img = single(img_);
            tags = strrep(stackstr(), "parc_3d", this.parc_tags);
            tags = strrep(tags, "_", "-");
            ifc.fileprefix = ifc.fileprefix + "-" + tags;
            ic1 = mlfourd.ImagingContext2(ifc);
        end
        function ic1 = reshape_to_parc_4d(this, ic)
            %% ndims(ic) == 4 => ndims(ic1) == 2

            assert(ndims(ic) == 4)            
            ifc = ic.imagingFormat;

            sz = size(ifc);
            % assert(prod(sz(1:3)) == length(this.select_vec));  % ensure that select_ic is compatible with ic
            Nt = size(ifc, 4);
            ifc_mat = reshape(ifc.img, [prod(sz(1:3)), Nt]);
            ifc.img = [];  % conserve memory
            img_ = zeros(this.Nx, Nt, "single");
            for idx = 1:this.Nx
                idx_select = this.select_vec == this.unique_indices(idx);
                img_(idx, :) = mean(ifc_mat(idx_select,:), 1, "omitnan");
            end
            ifc.img = single(img_);
            tags = strrep(stackstr(), "parc_4d", this.parc_tags);
            tags = strrep(tags, "_", "-");
            ifc.fileprefix = ifc.fileprefix + "-" + tags;
            ic1 = mlfourd.ImagingContext2(ifc);
        end
    end
    
    methods (Static)
        function this = create(varargin)
            %% 
            % 
            % opts.bids_kit mlkinetics.BidsKit {mustBeNonempty} % prototype for parcs & segs from Wmparc, Schaeffer, etc. 
            % opts.representation_kit = [] % mlkinetics.RepresentationKit {mustBeNonempty} % prototype
            % opts.scanner_kit = [] 
            % opts.parc_tags {mustBeText}

            this = mlkinetics.ParcSchaeffer(varargin{:});

            med = this.bids_kit_.make_bids_med();
            this.mlsurfer_schaeffer_ = mlsurfer.Schaeffer.create(med.imagingContext);  % not schaeffer_ic which is in space of T1w

            if contains(this.parc_tags_, "schaeffer-schaeffer")                
                this.select_ic_ = this.mlsurfer_schaeffer_.schaeffer;
                return
            end
            if contains(this.parc_tags_, "select-all")                
                this.select_ic_ = this.mlsurfer_schaeffer_.select_all();
                return
            end
            if contains(this.parc_tags_, "select-brain")                
                this.select_ic_ = this.mlsurfer_schaeffer_.select_brain();
                return
            end
            if contains(this.parc_tags_, "select-gm")                
                this.select_ic_ = this.mlsurfer_schaeffer_.select_gm();
                return
            end
            if contains(this.parc_tags_, "select-wm")                
                this.select_ic_ = this.mlsurfer_schaeffer_.select_wm();
                return
            end
            if contains(this.parc_tags_, "select-subcortical")                
                this.select_ic_ = this.mlsurfer_schaeffer_.select_subcortical();
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
        mlsurfer_schaeffer_
    end

    methods
        function this = ParcSchaeffer(varargin)
            this = this@mlkinetics.Parc(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
