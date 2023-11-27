classdef (Sealed) RepresentationKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for atlas registrations and volumetric or surface representations.
    %  It is an extensible factory making using of the prototype pattern (cf. GoF pp. 90-91, 117, 122).
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %
    %  
    %  Created 16-Aug-2023 13:26:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.
    
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
        function rep = make_representation(this, opts)
            %% makes a representation that provides atlas registrations and volumes or surfaces
            %  requires named Args:
            %  opts.bids_kit mlkinetics.BidsKit
            %  opts.representation_tags {mustBeTextScalar}

            arguments
                this mlkinetics.ModelKit
                opts.bids_kit mlkinetics.BidsKit
                opts.parc_kit = []
                opts.representation_tags {mustBeTextScalar} = this.proto_registry_.keys
            end
            opts.representation_tags = string(ensurecell1(opts.representation_tags));

            if this.proto_registry_.isKey(opts.representation_tags) % find proto using only representation_tags(1)
                rep = copy(this.proto_registry_(opts.representation_tags));
                rep.initialize(bids_kit=opts.bids_kit, parc_kit=opts.parc_kit);
            else % install proto in registry
                copts = namedargs2cell(opts);
                rep = this.install_representation(copts{:});
            end
        end        
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.RepresentationKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
        end
    end

    methods (Static)

        %% convenience create-methods for clients

        function this = create(opts)
            %% bids_kit, counter_tags must be non-empty collections

            arguments
                opts.representation_tags {mustBeText} = ""
            end

            this = mlkinetics.RepresentationKit();
            this.proto_registry_ = containers.Map();
            for idx = 1:length(opts.representation_tags)
                opts1 = opts;
                opts1.representation_tags = opts1.representation_tags(idx);
                copts1 = namedargs2cell(opts1);
                this.install_representation(copts1{:});
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
        function rep = install_representation(this, opts)
            arguments
                this mlkinetics.RepresentationKit
                opts.representation_tags {mustBeText} = ""
                opts.parc_kit = []
            end

            rep = [];
            if contains(opts.representation_tags, "hcp", IgnoreCase=true)
                rep = mlpipeline.HCP.create();
            end
            if contains(opts.representation_tags, "ciftify", IgnoreCase=true)
                rep = mlpipeline.Ciftify.create();
            end
            if contains(opts.representation_tags, "ants2mni", IgnoreCase=true)
                rep = mlfsl.Ants2MNI.create();
            end
            if contains(opts.representation_tags, "flirt2mni", IgnoreCase=true)
                rep = mlfsl.Flirt2MNI.create();
            end
            if contains(opts.representation_tags, "flirt2native", IgnoreCase=true) 
                % volume representation on the subject's native anatomy
                rep = mlfsl.Flirt2Native.create();
            end
            if contains(opts.representation_tags, "trivial", IgnoreCase=true) 
                % trivial case
                rep = mlkinetics.Representation.create();
            end

            % store
            this.proto_registry_(opts.representation_tags) = rep;
        end
        function this = RepresentationKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
