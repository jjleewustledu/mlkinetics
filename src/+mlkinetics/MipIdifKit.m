classdef (Sealed) MipIdifKit < handle & mlkinetics.IdifKit
    %% line1
    %  line2
    %  
    %  Created 16-Jul-2023 23:28:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2286388 (R2023a) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function ic = do_make_activity(this)
            ic = this.scanner_kit_.do_make_activity(decayCorrected=true);
            ic = this.buildMipIdif(ic);
        end
        function ic = do_make_activity_density(this)
            ic = this.scanner_kit_.do_make_activity_density(decayCorrected=true);
            ic = this.buildMipIdif(ic);
        end
        function dev = do_make_device(this)
            this.device_ = this.scanner_kit_.do_make_device();
            dev = this.device_;
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
        function idif_ic = buildMipIdif(this, activity_density_ic, opts)
            arguments
                this mlkinetics.MipIdifKit
                activity_density_ic mlfourd.ImagingContext2 {mustBeNonempty}
                opts.needs_reregistration logical = false
                opts.verbose double = 0
                opts.use_cache logical = false
            end

            mipidif = mlaif.MipIdif.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_, ...
                scanner_kit=this.scanner_kit_);
            idif_ic = mipidif.call(pet_dyn=activity_density_ic);
            idif_ic.addJsonMetadata(opts);
            idif_ic.save();
            this.input_func_ic_ = idif_ic;
        end
        function this = MipIdifKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
