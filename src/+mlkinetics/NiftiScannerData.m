classdef NiftiScannerData < handle & mlpet.AbstractScannerData
    %% NIFTISCANNERDEVICE restricts its scope to information in NIfTI.
    %  Does not manage cross-calibrations.  Prefer mlsiemens.BiographDevice for managing calibrations.
    %  
    %  Created 27-Nov-2023 03:38:07 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties
    end

    methods (Static)
        function consoleTaus(varargin)
            error('mlkinetics:NotImplementedError', stackstr());
        end
        function this = create(bids_med, opts)
            arguments
                bids_med mlpipeline.ImagingMediator {mustBeNonempty}
                opts.counter = [];
            end

            this = mlkinetics.NiftiScannerData( ...
                'isotope', bids_med.isotope, ...
                'tracer', bids_med.tracer, ...
                'datetimeMeasured', bids_med.datetime, ...
                'times', bids_med.times, ...
                'taus', bids_med.taus, ...
                'radMeasurements', opts.counter);
            this.imagingContext_ = bids_med.imagingContext;
        end
        function petPointSpread()
            error('mlkinetics:NotImplementedError', stackstr());
        end
    end

	methods
        function this = NiftiScannerData(varargin)
 			%% NIFTISCANNERDATA
            %  @param isotope in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %  @param tracer.
            %  @param datetimeMeasured is the measured datetime for times(1).  MANDATORY.
 			%  @param datetimeForDecayCorrection.
            %  @param dt is numeric and must satisfy Nyquist requirements of the client.
 			%  @param taus  are frame durations.
 			%  @param time0 >= this.times(1).
 			%  @param timeF <= this.times(end).
 			%  @param times are frame starts.

            this = this@mlpet.AbstractScannerData(varargin{:}, decayCorrected = true);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
