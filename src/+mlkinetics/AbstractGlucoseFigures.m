classdef AbstractGlucoseFigures 
	%% ABSTRACTGLUCOSEFIGURES  

	%  $Revision$
 	%  was created 09-Apr-2017 04:11:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Abstract)
        xlsx
    end
    
	properties 		
        xlsxSheet = 'Sheet1';
        mapKinetics
        mapMetab
        mapSx

        axesFontSize = 14
        axesLabelFontSize = 16
        boxFontSize = 14
        boxFormat = '%4.2f'
        barWidth = 180
        capLineWidth = 2
        capSize = 20;
        legendLocation = 'North'
        markerEdgeColor   = [0 0 0]
        markerEdgeColor95 = [0.8 0.309 0.1]
        markerEdgeColor75 = [0.1 0.309 0.8]
        markerFaceColor   = [1 1 1]
        markerFaceColor95 = [1 1 1]
        markerFaceColor75 = [0 0 0]
        markerLineWidth = 1
        markerSize = 120;
        
        magenta = [255 51 204]
        navy = [20 43 140]/255
        cyan = [0 200 220]/255
        
        nominalGlu      = [300 100]
        nominalRising   = [100 300]
        nominalRisingSI = [2.5 3.3 4.2 5.0]
        
        p
        scan
        nominal_glu
        
        subject
        visit
        ROI
        plasma_glu
        Hct
        WB_glu
        CBV        
        k21
        std_k21
        k12
        std_k12
        k32
        std_k32
        k23
        std_k23
        t0
        std_t0
        chi
        Kd
        CTXglu
        CMRglu
        free_glu
        
        CBF
        MTT
        Glucagon
        Epi
        Norepi
        Insulin
        Cortisol 
        dx = .1/7;
 	end

	methods		  
 		function this = AbstractGlucoseFigures(varargin)
 			%% ABSTRACTGLUCOSEFIGURES
 			%  Usage:  this = AbstractGlucoseFigures()
 			
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData') || isempty(x));
            parse(ip, varargin{:});            
            this.sessionData_ = ip.Results.sessionData;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

