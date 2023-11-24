classdef (Sealed) MipIdifKit < handle & mlkinetics.IdifKit
    %% line1
    %  line2
    %  
    %  Created 16-Jul-2023 23:28:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2286388 (R2023a) Update 3 for MACI64.  Copyright 2023 John J. Lee.

    methods
        function ic = do_make_activity(this)
            ic = this.scanner_kit_.do_make_activity(decayCorrected=this.decayCorrected);
            ic = this.buildMipIdif(ic);
            ic = ic*this.recovery_coeff;
        end
        function ic = do_make_activity_density(this, varargin)
            ic = this.scanner_kit_.do_make_activity_density(decayCorrected=this.decayCorrected);
            ic = this.do_make_input_func(ic, varargin{:});
            ic = ic*this.recovery_coeff;
        end
        function dev = do_make_device(this)
            this.device_ = this.scanner_kit_.do_make_device();
            dev = this.device_;
        end       
        function idif_ic = do_make_input_func(this, opts)
            arguments
                this mlkinetics.MipIdifKit
                opts.needs_reregistration logical = false
                opts.verbose double = 0
                opts.use_cache logical = false
                opts.pet_avgt = []
                opts.pet_mipt = []
                opts.steps logical = true(1,4)
            end

            mipidif = mlaif.MipIdif.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_, ...
                scanner_kit=this.scanner_kit_, ...
                pet_avgt=opts.pet_avgt, ...
                pet_mipt=opts.pet_mipt);
            idif_ic = mipidif.build_all(pet_dyn=activity_density_ic, steps=opts.steps);
            idif_ic.addJsonMetadata(opts);
            idif_ic.save();
            this.input_func_ic_ = idif_ic;
        end
    end

    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if (isempty(uniqueInstance))
                this = mlkinetics.MipIdifKit();
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
        function this = MipIdifKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end