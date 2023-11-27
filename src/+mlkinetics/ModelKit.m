classdef (Sealed) ModelKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for kinetic models.
    %  It is an extensible factory making using of the prototype pattern (cf. GoF pp. 90-91, 117, 122).
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  
    %  Created 02-May-2023 14:20:14 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
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
        function mdl = make_model(this, opts)
            %% makes a parameterized model without solving it
            %  requires named Args:
            %  opts.model_tags {mustBeTextScalar}

            arguments
                this mlkinetics.ModelKit
                opts.bids_kit = []
                opts.tracer_kit = []
                opts.scanner_kit = []
                opts.input_func_kit = []            
                opts.representation_kit = []              
                opts.parc_kit = []
                opts.data struct = struct([])
                opts.model_tags {mustBeText} = this.proto_registry_.keys
            end
            opts.model_tags = string(ensurecell1(opts.model_tags));

            if this.proto_registry_.isKey(opts.model_tags) % find proto using only model_tags(1)
                mdl = copy(this.proto_registry_(opts.model_tags));
                if ~isempty(opts.bids_kit) || ...
                        ~isempty(opts.tracer_kit) || ...
                        ~isempty(opts.scanner_kit) || ...
                        ~isempty(opts.input_func_kit) || ...
                        ~isempty(opts.representation_kit) || ...
                        ~isempty(opts.parc_kit) || ...
                        ~isempty(opts.data) % model state is determined by these parameter objects
                    mdl.initialize( ...
                        bids_kit=opts.bids_kit, ...
                        tracer_kit=opts.tracer_kit, ...
                        scanner_kit=opts.scanner_kit, ...
                        input_func_kit=opts.input_func_kit, ...
                        representation_kit=opts.representation_kit, ...
                        parc_kit=opts.parc_kit, ...
                        data=opts.data);
                end
            else % install proto in registry
                copts = namedargs2cell(opts);
                mdl = this.install_model(copts{:});
            end
        end
        function soln = make_solution(this, varargin)
            %% makes a parameterized model and solves it

            mdl = this.make_model(varargin{:});
            soln = mdl.build_solution();
        end
        function h = plot(this, tag, varargin)
            h = plot(this.proto_registry_(tag), varargin{:});
        end
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.ModelKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
        end
    end

    methods (Static)
        function this = create(opts)
            %% bids_kit, tracer_kit have loaded prototype registries.
            %  scanner_kit is a singleton. 
            %  input_func_kit, parc_kit, data, model_tags must be non-empty collections.

            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty} % prototype
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty} % prototype
                opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty} % singleton
                opts.input_func_kit mlkinetics.InputFuncKit {mustBeNonempty} % singleton
                opts.representation_kit = [] % mlkinetics.RepresentationKit {mustBeNonempty} % prototype
                opts.parc_kit = [] % mlkinetics.ParcKit {mustBeNonempty} % prototype
                opts.data struct 
                opts.model_tags {mustBeText}
            end

            this =  mlkinetics.ModelKit();
            this.proto_registry_ = containers.Map();
            for idx = 1:length(opts.model_tags)
                opts1 = opts;
                opts1.input_func_kit = opts1.input_func_kit(idx);
                %opts1.representation_kit = opts1.representation_kit(idx);
                %opts1.parc_kit = opts1.parc_kit(idx);
                try
                    if ~isempty(opts1.data)
                        opts1.data = opts1.data(idx);
                    end
                catch ME
                    handwarning(ME)
                end
                opts1.model_tags = opts1.model_tags(idx);
                copts1 = namedargs2cell(opts1);
                this.install_model(copts1{:});
            end
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
        function mdl = install_model(this, opts)
            %% Instantiates concrete model from tags and factories needed by the model,
            %  then stores the model in the prototype registry.  All models are clonable & can initialize.
            %  model_tags must be scalar.

            arguments
                this mlkinetics.ModelKit
                opts.bids_kit = []
                opts.tracer_kit = []
                opts.scanner_kit = []
                opts.input_func_kit = []                
                opts.representation_kit = []
                opts.parc_kit = []
                opts.data struct = struct([])
                opts.model_tags {mustBeTextScalar}
            end

            mdl = [];

            %% decay-uncorrected models
            
            if any(contains(opts.model_tags, "mintun1984", IgnoreCase=true))
                opts.scanner_kit.decayUncorrect();
                opts.input_func_kit.decayUncorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                if any(contains(opts.model_tags, "quadratic", IgnoreCase=true))
                    mdl = mlkinetics.QuadraticMintun1984Model.create(copts{:});
                else
                    mdl = mlkinetics.Mintun1984Model.create(copts{:});
                end
            end
            if any(contains(opts.model_tags, "raichle1983", IgnoreCase=true))
                opts.scanner_kit.decayUncorrect();
                opts.input_func_kit.decayUncorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                if any(contains(opts.model_tags, "quadratic", IgnoreCase=true))
                    mdl = mlkinetics.QuadraticRaichle1983Model.create(copts{:});
                else
                    mdl = mlkinetics.Raichle1983Model.create(copts{:});
                end
            end

            %% decay-corrected models

            if any(contains(opts.model_tags, "martin1987", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                if any(contains(opts.model_tags, "quadratic", IgnoreCase=true))
                    mdl = mlkinetics.QuadraticMartin1987Model.create(copts{:});
                else
                    mdl = mlkinetics.Martin1987Model.create(copts{:});
                end
            end
            if any(contains(opts.model_tags, "huang1980", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Huang1980Model.create(copts{:});
            end
            if any(contains(opts.model_tags, "2tcm", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.TwoTCModel.create(copts{:});
            end
            if any(contains(opts.model_tags, "ichise2002", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Ichise2002Model.create(copts{:});
            end
            if any(contains(opts.model_tags, "logan1990", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Logan1990Model.create(copts{:});
            end
            if any(contains(opts.model_tags, "logan1996", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Logan1996Model.create(copts{:});
            end
            if any(contains(opts.model_tags, "ichise2003", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Ichise2003Model.create(copts{:});
            end
            if any(contains(opts.model_tags, "wu2002", IgnoreCase=true))
                opts.scanner_kit.decayCorrect();
                opts.input_func_kit.decayCorrect();
                save(opts.input_func_kit);
                copts = namedargs2cell(opts);
                mdl = mlkinetics.Wu2002Model.create(copts{:});
            end
            if isempty(mdl)
                error("mlkinetics:ValueError", ...
                    "%s: model tags %s not supported", stackstr(), opts.model_tags)
            end

            % store
            this.proto_registry_(opts.model_tags) = mdl;
        end
        function this = ModelKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
