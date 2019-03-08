classdef AbstractKineticsModel < mlbayesian.NullModel & mlkinetics.IKineticsModel
	%% ABSTRACTKINETICSMODEL  

	%  $Revision$
 	%  was created 12-Dec-2017 22:41:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee. 	
    
    properties (Dependent)
        aifSpecificActivity
        aifSpecificActivityInterp
        aifTimes
        aifTimesInterp
        scannerSpecificActivity
        scannerSpecificActivityInterp
        scannerTimes
        scannerTimesInterp
        sessionData
    end
    
	methods 
        
        %% GET
        
        function g = get.aifSpecificActivity(this)
            g = this.aifBuilder_.specificActivity;
        end
        function g = get.aifSpecificActivityInterp(this)
            g = this.aifBuilder_.specificActivityInterpolants;
        end
        function g = get.aifTimes(this)
            g = this.aifBuilder_.times;
        end
        function g = get.aifTimesInterp(this)
            g = this.aifBuilder_.timeInterpolants;
        end
        function g = get.scannerSpecificActivity(this)
            g = this.scannerBuilder_.specificActivity;
        end
        function g = get.scannerSpecificActivityInterp(this)
            g = this.scannerBuilder_.specificActivityInterpolants;
        end
        function g = get.scannerTimes(this)
            g = this.scannerBuilder_.times;
        end
        function g = get.scannerTimesInterp(this)
            g = this.scannerBuilder_.timeInterpolants;
        end
        function g = get.sessionData(this)
            g = this.scannerBuider_.sessionData;
        end

        %%
        
        function plot(this, varargin)
            figure;
            plot(this.aifTimes, this.aifSpecificActivity, 's',  ...
                 this.scannerTimes, this.scannerSpecificActivity, 'o',  ...
                 this.scannerTimes, this.estimateData,  '-', varargin{:});
            legend('aif data', 'scanner data', 'estimated');  
            title(class(this));
        end
		  
 		function this = AbstractKineticsModel(varargin)
 			%% ABSTRACTKINETICSMODEL
 			%  @param named scannerBuilder is an mlpet.IScannerBuilder
 			%  @param named aifBuilder     is an mlpet.IAifBuilder
 			%  @param named blindedData    is an mlraichle.BlindedData
            %  @param named useSynthetic   is logical            
            %  @param named sessionData    is an mlraichle.SessionData
            %  @param named datedFilename  is logical
 			
            this = this@mlbayesian.NullModel(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scannerBuilder',     @(x) isa(x, 'mlpet.IScannerBuilder'));
            addParameter(ip, 'aifBuilder',         @(x) isa(x, 'mlpet.IAifBuilder'));
            addParameter(ip, 'blindedData',        @(x) isa(x, 'mlpet.IBlindedData'));
            addParameter(ip, 'calibrationBuilder', @(x) isa(x, 'mlpet.ICalibrationBuilder'));
            parse(ip, varargin{:});            
            this.scannerBuilder_     = ip.Results.scannerBuilder;
            this.aifBuilder_         = ip.Results.aifBuilder;
            this.blindedData_        = ip.Results.blindedData;
            this.calibrationBuilder_ = ip.Results.calibrationBuilder;
            
            this = this.setupKernel;           
            this = this.setupFilesystem;
            this = this.checkModel;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        scannerBuilder_
        aifBuilder_
        blindedData_
        calibrationBuilder_
    end
    
    methods (Access = protected)
        function this = setupKernel(this)
            if (this.useSynthetic)
                this = this.constructSyntheticKernel;
            else 
                this = this.constructKernelWithData;
            end  
        end
        function this = setupFilesystem(this)
            %% for mlio.AbstractIO
            this.filepath_ = this.sessionData.sessionPath;
            this.fileprefix_ = strrep(class(this), '.', '_');
            if (this.datedFilename_)
                this.fileprefix_ = [this.fileprefix_ '_' mydatetimestr(now)];
            end
            this.filesuffix_ = '.mat';
        end    
        function ps   = mcmcParameters(this)
            %% MCMCPARAMETERS must be in heap memory for speed
            %  @return struct containing:
            %  fixed      is logical, length := length(this.modelParameters)
            %  fixedValue is numeric, "
            %  min        is numeric, "; for prior distribution
            %  mean       is numeric, "
            %  max        is numeric, "; for prior distribution
            %  std        is numeric, "; for annealing
            %  nAnneal    =  20, number of loops per annealing temp
            %  nBeta      =  50, number of temperature steps
            %  nPop       =  50, number of population for annealing/burn-in and proposal/sampling
            %  nProposals = 100, number of proposals for importance sampling
            %  nSamples   is numeric, numel of independentData
            
            ps  = ensureColVector(this.modelParameters);
            sps = ensureColVector(this.modelStdParameters);
            ps = struct( ...
                'fixed',      false(size(ps)), ...
                'fixedValue', nan(size(ps)), ...
                'min_',       ps - this.M*sps, ...
                'mean_',      ps, ...
                'max_',       ps + this.M*sps, ... 
                'std_',       sps, ...
                'nAnneal',    40, ...
                'nBeta',      100, ...
                'nPop',       50, ...
                'nProposals', 100, ...
                'nSamples',   numel(this.independentData));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
