classdef (Abstract) Parc < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 09-Oct-2023 22:01:23 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods (Abstract)
        reshape_from_parc(this, ic1)
        reshape_to_parc(this, ic)
    end

    methods (Abstract, Static)
        create()
    end

    %% Shared Implementations

    properties (Dependent)
        dlicv_ic
        parc_tags
    end

    methods %% GET
        function g = get.dlicv_ic(this)
            med = this.bids_kit_.make_bids_med();
            g = med.dlicv_ic;
        end
        function g = get.parc_tags(this)
            g = this.parc_tags_;
        end
    end
    
    methods
        function this = initialize(this, opts)
            arguments
                this mlkinetics.Parc
                opts.bids_kit = []          
                opts.representation_kit = []  
                opts.scanner_kit = []
                opts.parc_tags = []
            end

            for f = asrow(fields(opts))
                if ~isempty(opts.(f{1}))
                    this.(strcat(f{1}, "_")) = opts.(f{1});
                end
            end
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_
        parc_tags_    
        representation_kit_
        scanner_kit_
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.representation_kit_)
                that.representation_kit_ = copy(this.representation_kit_); end
            if ~isempty(this.scanner_kit_)
                that.scanner_kit = copy(this.scanner_kit_); end
        end
        function this = Parc(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty} % prototype
                opts.representation_kit = [] % mlkinetics.RepresentationKit {mustBeNonempty} % prototype
                opts.scanner_kit = [] 
                opts.parc_tags {mustBeText}
            end
            copts = namedargs2cell(opts);
            this.initialize(copts{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
