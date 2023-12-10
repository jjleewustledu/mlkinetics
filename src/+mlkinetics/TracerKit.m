classdef (Sealed) TracerKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for PET radiotracers and primary measurements of their gamma radiation.
    %  It is an extensible factory making using of the prototype pattern (cf. GoF pp. 90-91, 117, 122).
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  
    %  TO DO: complete implementation as prototype.
    %
    %  Created 02-May-2023 14:17:31 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        proto_registry
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
        function cnt = make_handleto_counter(this, opts)
            %% bids_kit, counter_tags must be scalar

            arguments
                this mlkinetics.TracerKit
                opts.bids_kit = []
                opts.ref_source_props = []
                opts.tracer_tags {mustBeTextScalar} = ""
                opts.counter_tags {mustBeText} = this.proto_registry_.keys
            end
            opts.counter_tags = string(ensurecell1(opts.counter_tags));

            if this.proto_registry_.isKey(opts.counter_tags) % find proto using only tracer_tags(1)
                cnt = this.proto_registry_(opts.counter_tags);
            else % install proto in registry
                copts = namedargs2cell(opts);
                cnt = this.install_tracer(copts{:});
            end
        end
        function r = make_radionuclides(this)
            r = this.proto_radionuclides_; 
        end
        function r = make_ref_source(this)
            r = this.proto_ref_source_; 
        end
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.TracerKit
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
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.ref_source_props = []
                opts.tracer_tags {mustBeText} = ""
                opts.counter_tags {mustBeText}
            end

            this = mlkinetics.TracerKit();
            this.proto_registry_ = containers.Map();
            for idx = 1:length(opts.counter_tags)
                opts1 = opts;
                opts1.counter_tags = opts1.counter_tags(idx);
                copts1 = namedargs2cell(opts1);
                this.install_tracer(copts1{:});
            end

            assert(~isempty(this.proto_registry_.keys))
        end
    end
    
    %% PROTECTED

    properties (Access = protected)     
        proto_radionuclides_ % value class
        proto_ref_source_ % value class
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
        function cnt = install_tracer(this, opts)
            %% bids_Kit, counter_tags must be scalar

            arguments
                this mlkinetics.TracerKit
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.ref_source_props = [] % struct or datetime
                opts.tracer_tags {mustBeTextScalar} = ""
                opts.counter_tags {mustBeTextScalar}
            end

            if ~isempty(opts.ref_source_props)
                this.proto_ref_source_ = mlpet.ReferenceSource.create(opts.ref_source_props);
            end
            if isemptytext(opts.tracer_tags)
                med = opts.bids_kit.make_bids_med();
                rn = mlpet.Radionuclides(med.tracer);
                opts.tracer_tags = rn.isotope;
            end
            this.proto_radionuclides_ = mlpet.Radionuclides(opts.tracer_tags);

            cnt = [];
            if contains(opts.counter_tags, "caprac", IgnoreCase=true)
                cnt = mlpet.CCIRRadMeasurements.createFromSession( ...
                    opts.bids_kit.make_bids_med());
            end
            if contains(opts.counter_tags, "beckman", IgnoreCase=true)
                cnt = mlpet.BeckmanCounter.create();
            end
            if contains(opts.counter_tags, "hidex", IgnoreCase=true)
                cnt = mlpet.HidexCounter.create();
            end
            if contains(opts.counter_tags, "nocounter", IgnoreCase=true)
                cnt = mlpet.NoCounter.create();
            end
            if isempty(cnt)
                error("mlkinetics:ValueError", ...
                    "%s: counter tags %s not supported", stackstr(), opts.counter_tags)
            end

            % store
            this.proto_registry_(opts.counter_tags) = cnt;
        end
        function this = TracerKit()
        end
    end

    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
