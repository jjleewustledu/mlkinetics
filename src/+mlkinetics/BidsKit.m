classdef (Sealed) BidsKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for listmode, NIfTI, and other BIDS.
    %  It is an extensible factory making using of the prototype pattern (cf. GoF pp. 90-91, 117, 122).
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %
    %  Created 26-Apr-2023 19:13:24 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
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
        function m = make_raw_med(this)
            m = this.proto_raw_med_;
        end
        function m = make_recon_med(this)
            m = this.proto_recon_med_;
        end
        function m = make_reg_med(this)
            m = this.proto_reg_med_;
        end
        function med = make_bids_med(this, opts)
            %% bids_tags, bids_fqfn must be scalar

            arguments
                this mlkinetics.BidsKit
                opts.proto_raw_med = []
                opts.proto_recon_med = []
                opts.proto_reg_med = []
                opts.bids_tags string = this.proto_registry_.keys
                opts.bids_fqfn string = ""
            end
            opts.bids_tags = string(ensurecell1(opts.bids_tags));

            if this.proto_registry_.isKey(opts.bids_tags) % find proto using only bids_tags(1)
                med = copy(this.proto_registry_(opts.bids_tags));
                if ~isemptytext(opts.bids_fqfn) % mediator state is determined by opts.bids_fqfn
                    med.initialize(opts.bids_fqfn);
                end
            else % install proto in registry
                copts = namedargs2cell(opts);
                med = this.install_mediator(copts{:});
            end
        end
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.BidsKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
        end
    end

    methods (Static)
        function this = create(opts)
            %% bids_tags, bids_fqfn must be non-empty collections.

            arguments
                opts.proto_raw_med = []
                opts.proto_recon_med = []
                opts.proto_reg_med = []
                opts.bids_tags string
                opts.bids_fqfn string
            end

            this = mlkinetics.BidsKit();
            this.proto_registry_ = containers.Map();
            for idx = 1:length(opts.bids_tags)
                opts1 = opts;
                opts1.bids_tags = opts1.bids_tags(idx);
                opts1.bids_fqfn = opts1.bids_fqfn(idx);
                copts1 = namedargs2cell(opts1);
                this.install_mediator(copts1{:});
            end

            assert(~isempty(this.proto_registry_.keys))
        end
    end

    %% PROTECTED

    properties (Access = protected)
        proto_raw_med_
        proto_recon_med_
        proto_reg_med_
        proto_registry_
    end

    methods (Access = protected)
        function this = BidsKit()
        end
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            that.proto_registry_ = containers.Map;
            keys = asrow(this.proto_registry_.keys);
            for key = keys
                that.proto_registry_(key{1}) = copy(this.proto_registry_(key{1}));
            end
        end
        function med = install_mediator(this, opts) 
            %% bids_fqfn must be scalar.

            arguments
                this mlkinetics.BidsKit
                opts.proto_raw_med = []
                opts.proto_recon_med = []
                opts.proto_reg_med = []
                opts.bids_tags string
                opts.bids_fqfn string
            end
            
            if ~isempty(opts.proto_raw_med)
                this.proto_raw_med_ = opts.proto_raw_med;
            end
            if ~isempty(opts.proto_recon_med)
                this.proto_recon_med_ = opts.proto_recon_med;
            end
            if ~isempty(opts.proto_reg_med)
                this.proto_reg_med_ = opts.proto_reg_med;
            end

            med = [];
            if contains(opts.bids_tags, "ccir", IgnoreCase=true) && contains(opts.bids_tags, "1211")
                med = mlvg.Ccir1211Mediator(opts.bids_fqfn);
            end
            if contains(opts.bids_tags, "ccir", IgnoreCase=true) && contains(opts.bids_tags, "1351")
                med = mlwong.Ccir1351Mediator(opts.bids_fqfn);
            end
            if contains(opts.bids_tags, "ccir", IgnoreCase=true) && contains(opts.bids_tags, "993")
                med = mlan.Ccir993Mediator(opts.bids_fqfn);
            end
            if contains(opts.bids_tags, "ccir", IgnoreCase=true) && contains(opts.bids_tags, "559754")
                med = mlraichle.Ccir559754Mediator(opts.bids_fqfn);
            end
            if contains(opts.bids_tags, "simple", IgnoreCase=true)
                med = mlpipeline.SimpleMediator(opts.bids_fqfn);
            end
            if isempty(med)
                error("mlkinetics:ValueError", ...
                    "%s: mediator tags %s not supported", stackstr(), opts.bids_tags)
            end

            % store
            this.proto_registry_(opts.bids_tags) = med;
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
