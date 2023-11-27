classdef (Sealed) ParcKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for parcellations, segmentations, or voxels.
    %  It is an extensible factory making using of the prototype pattern (cf. GoF pp. 90-91, 117, 122).
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  
    %  Created 02-May-2023 14:24:53 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        proto_registry % contents of containers.Map are mutable
    end

    methods %% GET
        function g = get.proto_registry(this)
            g = this.proto_registry_;
        end
    end

    methods
        %% make related products, with specialty relationships specified by the factory
        
        function this = load(~, varargin)
            ld = load(varargin{:});
            this = ld.this;
        end
        function parc = make_parc(this, opts)
            arguments
                this mlkinetics.ParcKit
                opts.bids_kit = []
                opts.representation_kit = []
                opts.parc_tags {mustBeText} = this.proto_registry_.keys
            end
            opts.parc_tags = string(ensurecell1(opts.parc_tags));

            if this.proto_registry_.isKey(opts.parc_tags) % find proto using only parc_tags(1)
                parc = copy(this.proto_registry_(opts.parc_tags));
            else % install proto in registry
                copts = namedargs2cell(opts);
                parc = this.install_parc(copts{:});
            end
        end
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.ParcKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
        end
    end

    methods (Static)
        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.representation_kit = []
                opts.parc_tags {mustBeText}
            end

            this = mlkinetics.ParcKit();
            this.proto_registry_ = containers.Map();
            for idx = 1:length(opts.parc_tags)
                opts1 = opts;
                opts1.parc_tags = opts1.parc_tags(idx);
                copts1 = namedargs2cell(opts1);
                this.install_parc(copts1{:});
            end

            assert(~isempty(this.proto_registry_.keys))
        end
    end
    
    %% PROTECTED

    properties (Access = protected)
        proto_registry_
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            that.proto_registry_ = containers.Map;
            keys = asrow(this.proto_registry_.keys);
            for key = keys
                that.proto_registry_(key{1}) = copy(this.proto_registry_(key{1}));
            end
        end
        function parc = install_parc(this, opts) 
            arguments
                this mlkinetics.ParcKit
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.representation_kit = []
                opts.parc_tags {mustBeText}
            end

            parc = [];
            if contains(opts.parc_tags, "schaeffer", IgnoreCase=true)
                parc = mlkinetics.SchaefferParc.create( ...
                    bids_kit=opts.bids_kit, ...
                    representation_kit=opts.representation_kit, ...
                    parc_tags=opts.parc_tags);
            end
            if contains(opts.parc_tags, "wmparc", IgnoreCase=true)
                parc = mlkinetics.ParcWmparc.create( ...
                    bids_kit=opts.bids_kit, ...
                    representation_kit=opts.representation_kit, ...
                    parc_tags=opts.parc_tags);
            end
            if contains(opts.parc_tags, "voxel", IgnoreCase=true)
                parc = mlkinetics.ParcVoxel.create( ...
                    bids_kit=opts.bids_kit, ...
                    representation_kit=opts.representation_kit, ...
                    parc_tags=opts.parc_tags);
            end
            if isempty(parc)
                error("mlkinetics:ValueError", ...
                    "%s: parc tags %s not supported", stackstr(), opts.parc_tags)
            end

            % store
            this.proto_registry_(opts.parc_tags) = parc;
        end
        function this = ParcKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
