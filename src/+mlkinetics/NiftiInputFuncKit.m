classdef NiftiInputFuncKit < handle & mlkinetics.IdifKit
    %% Supports any input function saved as NIfTI, but especially convenient for IDIFs.
    %  
    %  Created 17-Jul-2023 00:40:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2286388 (R2023a) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function ic = do_make_activity(this)
            %% Bq

            ic_ = do_make_activity_density(this);
            vox_vol = prod(ic_.mmppix)/1000; % mm^3 ~ \mu L
            ic = ic_*vox_vol;
        end
        function ic = do_make_activity_density(this)
            %% Bq/mL

            ic = copy(this.input_func_ic_);
        end
        function dev = do_make_device(this)
            dev = this.scanner_kit_.do_make_device();
        end
    end

    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if (isempty(uniqueInstance))
                this = mlkinetics.NiftiInputFuncKit();
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
            if ~isemptytext(this.input_func_fqfn_)
                this.input_func_ic_ = mlfourd.ImagingContext2(this.input_func_fqfn_);
            end
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = NiftiInputFuncKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
