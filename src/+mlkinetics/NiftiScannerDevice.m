classdef NiftiScannerDevice < handle & mlpet.AbstractScannerDevice
    %% NIFTISCANNERDEVICE restricts its scope to information in NIfTI.
    %  Does not manage cross-calibrations.  Prefer mlsiemens.BiographDevice for managing calibrations.
    %  
    %  Created 27-Nov-2023 03:38:12 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    methods (Static)
        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit = [] % unused but symmetric with Biograph*Device classes
            end

            import mlkinetics.*;
            bids_med = opts.bids_kit.make_bids_med();
            this = NiftiScannerDevice( ...
                data=NiftiScannerData.create(bids_med));

            this.invEfficiency_ = 1;   
            this.data_.imagingContext.json_metadata.invEfficiency = this.invEfficiency_; 
        end
        function ie = invEfficiencyf(varargin)        
            ie = 1;
        end
    end
    
    %% PRIVATE

	methods (Access = private)
        function this = NiftiScannerDevice(varargin)
 			this = this@mlpet.AbstractScannerDevice(varargin{:});        
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
