classdef (Abstract) MetabDirector < handle & mlpipeline.AbstractHandleDirector
	%% METABDIRECTOR  

	%  $Revision$
 	%  was created 17-Dec-2018 00:26:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods (Abstract)
        buildCalibration(this)
        buildAif(this)
        buildRoi(this)
        buildTac(this)
        buildLab(this)
        buildModel(this)
    end
    
    properties (Dependent)
        calBuilder
        aifBuilder
        roiBuilder
        tacBuilder
        labBuilder
        modelBuilder        
    end
    
    methods
        
        %% GET
        
        function g = get.calBuilder(this)
            g = this.calBuilder_;
        end
        function g = get.aifBuilder(this)
            g = this.aifBuilder_;
        end
        function g = get.roiBuilder(this)
            g = this.roiBuilder_;
        end
        function g = get.tacBuilder(this)
            g = this.tacBuilder_;
        end
        function g = get.labBuilder(this)
            g = this.labBuilder_;
        end
        function g = get.modelBuilder(this)
            g = this.builder_;
        end
        
        %%
        
        function construct(this)
            this.buildCalibration();
            this.buildAif();
            this.buildRoi();
            this.buildTac();
            this.buildLab();
            this.buildModel();
        end
        function writeResult(this)
            this.modelBuilder.writeResult();
        end
        
 		function this = MetabDirector(varargin)
 			%% METABDIRECTOR
 			%  @param .
 			
 			this = this@mlpipeline.AbstractHandleDirector(varargin{:});
             
            ip = inputParser;
            addParameter(ip, 'calBuilder', [], @(x) isa(x, 'mlpet.ICalibrationBuilder'));
            addParameter(ip, 'aifBuilder', [], @(x) isa(x, 'mlpet.IAifBuilder'));
            addParameter(ip, 'roiBuilder', [], @(x) isa(x, 'mlrois.IRoisBuilder'));
            addParameter(ip, 'tacBuilder', [], @(x) isa(x, 'mlpet.IScannerBuilder'));
            addParameter(ip, 'labBuilder', []);
            addParameter(ip, 'modelBuilder', [], @(x) isa(x, 'mlkinetics.IMetabBuilder'));
            parse(ip, varargin{:});
            this.calBuilder_ = ip.Results.calBuilder;
            this.aifBuilder_ = ip.Results.aifBuilder;
            this.roiBuilder_ = ip.Results.roiBuilder;
            this.tacBuilder_ = ip.Results.tacBuilder;
            this.labBuilder_ = ip.Results.labBuilder;
            this.builder_ = ip.Results.modelBuilder;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        calBuilder_
        aifBuilder_
        roiBuilder_
        tacBuilder_
        labBuilder_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

