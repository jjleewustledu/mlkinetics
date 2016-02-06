classdef KineticsFacade
	%% KINETICSFACADE  

	%  $Revision$
 	%  was created 08-Jan-2016 12:29:31
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	
    
	methods 
 		function this = KineticsFacade(varargin)
 			%% KINETICSFACADE
 			%  Usage:  this = KineticsFacade()

 			ip = inputParser;
            addParameter(ip, 'studyData',     [], @(x) isa(x, 'mlpipeline.StudyDataSingleton'));
            addParameter(ip, 'kineticsModel', [], @(x) isa(x, 'mlkinetics.IKineticsModel'));
            addParameter(ip, 'mcmcStrategy',  [], @(x) isa(x, 'mlbayesian.IMcmcStrategy'));
            parse(ip, varargin{:});
        end
        
        function this = estimateParameters(this)
            this.kineticsModel.studyData = this.studyData;
            this.kineticsModel.mcmcStrategy = this.mcmcStrategy;
            this.kineticsModel = this.kineticsModel.estimateParameters;
        end
        function viewKinetics(this)
            assert(this.kineticsModel.estimationsComplete);
            disp(this.parameterStats);
            this.viewAif;
            this.viewTac;
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

