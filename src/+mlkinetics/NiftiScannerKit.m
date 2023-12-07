classdef NiftiScannerKit < handle & mlkinetics.ScannerKit
    %% line1
    %  line2
    %  
    %  Created 26-Nov-2023 21:24:09 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    

    methods
        function d = do_make_device(this)
            if ~isempty(this.device_)
                d = this.device_;
                return
            end
            this.device_ = mlkinetics.NiftiScannerDevice.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_);
            d = this.device_;
        end   
        function ic = do_make_imaging(this, measurement_ic)
            %% provides class-consistent fqfp and noclobber info to measurement

            arguments
                this mlkinetics.NiftiScannerKit
                measurement_ic mlfourd.ImagingContext2
            end
            med_ = this.bids_kit_.make_bids_med();
            ic_ = med_.imagingContext;
            fp_ = ic_.fileprefix;
            if ~contains(fp_, stackstr(use_dashes=true))
                fp_ = mlpipeline.Bids.adjust_fileprefix( ...
                    ic_.fileprefix, post_proc=stackstr(use_dashes=true));
            end
            if ~contains(fp_, "_pet")
                fp_ = strcat(fp_, "_pet");
            end
            ic = measurement_ic;
            ic.fileprefix = fp_;
            ic.noclobber = this.noclobber;
        end
    end

    methods (Static)
        function this = instance(varargin)
            this = mlkinetics.NiftiScannerKit();
            this.install_scanner(varargin{:});

            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlsiemens.BiographVisionKit2();
            %     this.install_scanner(varargin{:});
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.install_scanner(varargin{:});
            % end
        end
    end 

    %% PROTECTED

    methods (Access = protected)
        function install_scanner(this, varargin)
            install_scanner@mlkinetics.ScannerKit(this, varargin{:});
        end
    end

    %% PRIVATE

    properties (Access = private)
    end

    methods (Access = private)
        function this = NiftiScannerKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
