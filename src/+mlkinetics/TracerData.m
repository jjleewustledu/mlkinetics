classdef TracerData < handle & mlpet.AbstractTracerData
    %% is a concrete factory ~ radiopharmaceutical at point of care
    %  
    %  Created 14-Jun-2022 00:45:02 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
	properties (Dependent)
        imagingContext
        radMeasurements
 		visibleVolume
    end

    methods

        %% GET

        function g = get.imagingContext(this)
            g = this.imagingContext_;
        end
        function     set.imagingContext(this, s)
            assert(isa(s, 'mlfourd.ImagingContext2') || isa(s, 'mlfourd.ImagingFormatContext2'))
            this.imagingContext_ = s;
            re = regexp(this.imagingContext.fileprefix, 'sub-\w+_ses-(?<dt>\d{14})_\S+', 'names');
            this.datetimeMeasured = datetime(re.dt, 'InputFormat', 'yyyyMMddHHmmss');
        end        
        function g = get.radMeasurements(this)
            if ~isempty(this.radMeasurements_)
                g = this.radMeasurements_;
                return
            end
            this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromDate(this.datetimeMeasured);
            this.datetimeMeasured = this.datetimeMeasured - this.clocksTimeOffsetWrtNTS;
        end
        function g = get.visibleVolume(this)
            %% mL
            
            nii = this.imagingContext.nifti;
            g = prod(nii.mmppix)/1e3;
        end

        %%

        function this = TracerData(varargin)
            %% TRACERDATA 
            %  Args:
            %      isotope (text): in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %      tracer (text).
            %      datetimeMeasured (datetime) is the recorded value for times(1).
 			%      datetimeForDecayCorrection (datetime).  Default = datetimeMeasured.
            %      dt (numeric): must satisfy Nyquist requirements of the client.  Default = 1.
 			%      taus (numeric): are frame durations.
 			%      time0 (numeric): >= this.times(1).  Default = -inf.
 			%      timeF (numeric): <= this.times(end).  Default = inf.
 			%      times (numeric): are frame starts.  Default = [].
            
            this = this@mlpet.AbstractTracerData(varargin{:})
            
            this.decayCorrected_ = true;
        end

        function a = activity(this, varargin)
            %% Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical.
            %  @param volumeAveraged is logical.
            %  @param diff is logical.
            
            a = this.activityDensity(varargin{:})*this.visibleVolume;
        end
        function a = activityDensity(this, varargin)
            %% Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical, default false.
            %  @param volumeAveraged is logical, default false.
            %  @param diff is logical, default false.
            %  @param uniformTimes is logical, default false.  Applicable only if volumeAveraged.
            
            ip = inputParser;
            addParameter(ip, 'decayCorrected', false, @islogical)
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isnat(x) || isdatetime(x))
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            addParameter(ip, 'timeAveraged', false, @islogical)
            addParameter(ip, 'volumeAveraged', false, @islogical)
            addParameter(ip, 'diff', false, @islogical)
            addParameter(ip, 'uniformTimes', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isdatetime(ipr.datetimeForDecayCorrection) && ...
                    ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end  
            if ~ipr.decayCorrected && this.decayCorrected
                this = this.decayUncorrect();
            end
            
            that = copy(this);
            if ipr.index0 ~= this.index0 || ipr.indexF ~= this.indexF
                that = that.selectIndex0IndexF(ipr.index0, ipr.indexF);
            end
            if ipr.timeAveraged
                that.imagingContext_ = that.imagingContext_.timeAveraged();
            end
            if ipr.volumeAveraged && ndims(that.imagingContext_) >= 3 %#ok<ISMAT>
                that.imagingContext_ = that.imagingContext_.volumeAveraged();                
                a = that.imagingContext_.nifti.img;
                if ipr.uniformTimes
                    a = interp1(this.timesMid, a, this.timeInterpolants);
                end
                if ipr.diff
                    a = diff(a);
                end
            else                
                if ipr.diff
                    that.imagingContext_ = diff(that.imagingContext_);
                end
                a = that.imagingContext_.nifti.img;
            end
        end
        function that = blurred(this, varargin)
            that = copy(this);
            that.imagingContext_ = that.imagingContext_.blurred(varargin{:});
        end
        function c = countRate(this, varargin)
            %% Bq/mL, decay-corrected.
            %  @param decayCorrected, default := true.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical.
            %  @param volumeAveraged is logical.
            %  @param diff is logical.
            
            c = this.activityDensity('decayCorrected', true, varargin{:});
        end
        function this = decayCorrect(this)
            if ~this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat .* this.decayCorrectionFactors;
                ifc.img = this.reshape_2d_to_native(mat);
                
                this.imagingContext_ = mlfourd.ImagingContext2(ifc);
                this.imagingContext_.fileprefix = ...
                    sprintf('%s_decayCorrect%g', ifc.fileprefix, this.timeForDecayCorrection);
                this.decayCorrected_ = true;
            end
        end
        function f = decayCorrectionFactors(this, varargin)
            %% DECAYCORRECTIONFACTORS
            %  @return f is vector with same shape at this.times.
            %  See also:  https://niftypet.readthedocs.io/en/latest/tutorials/corrqnt.html
            
            ip = inputParser;
            addParameter(ip, 'timeShift', 0, @isscalar)
            parse(ip, varargin{:})
            
            lambda = log(2)/this.halflife;
            times1 = this.times - this.timeForDecayCorrection - ip.Results.timeShift;
            Dtimes = (times1(2:end) - times1(1:end-1));
            Dtimes = [Dtimes this.taus(end)];
            f = lambda*Dtimes ./ (exp(-lambda*times1).*(1 - exp(-lambda*Dtimes)));
            f = reshape(f, size(asrow(times1)));
        end
        function this = decayUncorrect(this)
            if this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat ./ this.decayCorrectionFactors;
                ifc.img = this.reshape_2d_to_native(mat);
                
                this.imagingContext_ = mlfourd.ImagingContext2(ifc);
                this.imagingContext_.fileprefix = ...
                    sprintf('%s_decayUncorrect%g', ifc.fileprefix, this.timeForDecayCorrection);
                this.decayCorrected_ = false;
            end
        end
        function that = masked(this, varargin)
            that = copy(this);
            that.imagingContext_ = that.imagingContext_.masked(varargin{:});
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetimesMid' 'datetime', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity'}.
            
            ip = inputParser;
            addOptional(ip, 'abscissa', 'this.datetimesMid', @ischar)
            addOptional(ip, 'ordinate', 'this.activityDensity', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            that = copy(this);
            try
                that.imagingContext_ = that.imagingContext_.volumeAveraged();
            catch ME
                handwarning(ME)
            end
            h = plot@mlpet.AbstractTracerData(that, ipr.abscissa, ipr.ordinate);
        end
        function this = read(this, varargin)
            this.imagingContext_ = mlfourd.ImagingContext2(varargin{:});
            this = this.decayUncorrect();
        end
        function img  = reshape_native_to_2d(this, img)
            sz  = size(this.imagingContext.nifti);
            switch length(sz)
                case 2
                    return
                case 3                    
                    img = reshape(img, [sz(1)*sz(2) sz(3)]);
                case 4
                    szimg = size(img);
                    img = reshape(img, [sz(1)*sz(2)*sz(3) max(sz(4), szimg(end))]);
                otherwise
                    error('mlsiemens:RuntimeError', 'BiographData.reshape_native_to_2d')
            end
        end
        function img  = reshape_2d_to_native(this, img)
            sz  = size(this.imagingContext.nifti);
            switch length(sz)
                case 2
                    return
                case 3                    
                    img = reshape(img, [sz(1) sz(2) sz(3)]);
                case 4
                    szimg = size(img);
                    img = reshape(img, [sz(1) sz(2) sz(3) max(sz(4), szimg(end))]);
                otherwise
                    error('mlsiemens:RuntimeError', 'BiographData.reshape_2d_to_native')
            end
        end
        function this = shiftWorldlines(this, Dt, varargin)
            %% shifts worldline of internal data self-consistently
            %  @param required Dt is scalar:  timeShift > 0 shifts into future; timeShift < 0 shifts into past.
            %  @param shiftDatetimeMeasured is logical.
            
            ip = inputParser;
            addRequired(ip, 'timeShift', @isscalar)
            addParameter(ip, 'shiftDatetimeMeasured', true, @islogical)
            parse(ip, Dt, varargin{:})
            assert(isscalar(this.halflife))
            
            ifc = this.imagingContext.nifti;
            ifc.img = ifc.img * 2^(-Dt/this.halflife);            
            this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_shiftWorldlines%g', ifc.fileprefix, Dt));
            
            if ip.Results.shiftDatetimeMeasured
                this.datetimeMeasured = this.datetimeMeasured + seconds(Dt);
            end
        end
        function that = timeAveraged(this, varargin)
            that = copy(this);
            that.imagingContext_ = that.imagingContext_.timeAveraged(varargin{:});
        end
        function that = volumeAveraged(this, varargin)
            that = copy(this);
            that.imagingContext_ = that.imagingContext_.volumeAveraged(varargin{:});
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        imagingContext_
        radMeasurements_
    end

    methods (Access = protected)         
        function sec  = clocksTimeOffsetWrtNTS(this)
            try
                sec = seconds(this.radMeasurements_.clocks.TimeOffsetWrtNTS____s('mMR console'));
            catch ME
                handwarning(ME)
                sec = seconds(this.radMeasurements_.clocks.TIMEOFFSETWRTNTS____S('mMR console'));
            end
        end 
        function this = selectIndex0IndexF(this, index0, indexF)
            nii = this.imagingContext.nifti;
            switch nii.ndims
                case 2
                    nii.img = nii.img(index0:indexF);
                case 3
                    nii.img = nii.img(:,:,index0:indexF);
                case 4
                    nii.img = nii.img(:,:,:,index0:indexF);
                otherwise
                    error('mlkinetics:ValueError', 'TracerData.selectIndex0IndexF')
            end
            this.imagingContext_ = mlfourd.ImagingContext2(nii);
        end
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.imagingContext_ = copy(this.imagingContext_);
            that.radMeasurements_ = copy(this.radMeasurements_);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
