classdef (Sealed) FungIdifKit < handle & mlkinetics.IdifKit
    %% line1
    %  line2
    %  
    %  Created 16-Jul-2023 23:28:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2286388 (R2023a) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function ic = do_make_activity(this, varargin)
            %% DO_MAKE_ACTIVITY ~ Bq
            %  Args:
            %     this mlaif.FungIdifKit
            %     activity_density_ic mlfourd.ImagingContext2 {mustBeNonempty}
            %     opts.mpr_coords cell = {}
            %     opts.needs_reregistration logical = false
            %     opts.verbose double = 0
            %     opts.use_cache logical = false
            %     opts.k double {mustBeScalarOrEmpty} = 4
            %     opts.t double {mustBeVector} = [0 0 0 0.2 0.4 0.6 0.8 1 1 1]

            ic = this.scanner_kit_.do_make_activity(decayCorrected=this.decayCorrected);
            ic = this.do_make_input_func(ic, varargin{:});
        end
        function ic = do_make_activity_density(this, varargin)
            %% DO_MAKE_ACTIVITY ~ Bq/mL
            %  Args:
            %     this mlaif.FungIdifKit
            %     activity_density_ic mlfourd.ImagingContext2 {mustBeNonempty}
            %     opts.mpr_coords cell = {}
            %     opts.needs_reregistration logical = false
            %     opts.verbose double = 0
            %     opts.use_cache logical = false
            %     opts.k double {mustBeScalarOrEmpty} = 4
            %     opts.t double {mustBeVector} = [0 0 0 0.2 0.4 0.6 0.8 1 1 1]

            ic = this.scanner_kit_.do_make_activity_density(decayCorrected=this.decayCorrected);
            ic = this.do_make_input_func(ic, varargin{:});
        end
        function dev = do_make_device(this)
            this.device_ = this.scanner_kit_.do_make_device();
            dev = this.device_;
        end
        function idif_ic = do_make_input_func(this, activity_density_ic, opts)
            arguments
                this mlaif.FungIdifKit
                activity_density_ic mlfourd.ImagingContext2 {mustBeNonempty}
                opts.mpr_coords cell = {}
                opts.needs_reregistration logical = false
                opts.verbose double = 0
                opts.use_cache logical = false
                opts.k double {mustBeScalarOrEmpty} = 4
                opts.t double {mustBeVector} = [0 0 0 0.2 0.4 0.6 0.8 1 1 1]
            end
            med = this.bids_kit_.make_bids_med();
            med.initialize(activity_density_ic);

            fung2013 = mlaif.Fung2013.createForT1w( ...
                bids=med, ...
                coord1=opts.mpr_coords{c}(1,:), ...
                coord2=opts.mpr_coords{c}(2,:), ...
                timesMid=med.timesMid, ...
                needs_reregistration=opts.needs_reregistration, ...
                verbose=opts.verbose);
            idif_ic = fung2013.build_all(pet_dyn=activity_density_ic, use_cache=opts.use_cache, k=opts.k, t=opts.t);
            idif_ic.addJsonMetadata(opts);
            idif_ic.save();
            this.input_func_ic_ = idif_ic;
        end
    end

    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if (isempty(uniqueInstance))
                this = mlkinetics.FungIdifKit();
                this.install_input_func(varargin{:})
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.install_input_func(varargin{:})
            end
        end
    end 

    %% PROTECTED

    methods (Access = protected)
        function install_input_func(this, varargin)
            install_input_func@mlkinetics.InputFuncKit(this, varargin{:});
        end
    end

    %% PRIVATE 

    methods (Access = private)
        function this = FungIdifKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
