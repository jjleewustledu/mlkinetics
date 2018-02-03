classdef Test_KineticsFacade < matlab.unittest.TestCase
	%% TEST_KINETICSFACADE 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_KineticsFacade)
 	%          >> result  = run(mlkinetics_unittest.Test_KineticsFacade, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 08-Jan-2016 12:29:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
 		testObj
    end
    
    properties (Dependent)
        ecatPath
        ecat_fqfn
        mask_fqfn
        dcv_fqfn
        subjectsDir
        sessionPath
        plotParameters_mat
        plotGroupParameters_mat
    end
    
    methods %% GET
        function g = get.ecatPath(this)
            g = fullfile(this.sessionPath, 'ECAT_EXACT', '');
        end
        function g = get.ecat_fqfn(this)
            g = fullfile(this.ecatPath, 'pet', 'p7686ho1_frames', 'p7686ho1.nii.gz');
        end
        function g = get.mask_fqfn(this)
            g = fullfile(this.ecatPath, 'aparc_a2009s+aseg_on_p7686ho1_sumt.nii.gz');
        end
        function g = get.dcv_fqfn(this)
            g = fullfile(this.ecatPath, 'pet', 'p7686ho1.dcv');
        end
        function g = get.subjectsDir(~)
            g = getenv('MLUNIT_TEST_PATH', 'cvl', 'np755', '');
        end
        function g = get.sessionPath(this)
            g = fullfile(this.subjectsDir, 'mm01-007_p7686_2010aug20', '');
        end
        function g = get.plotParameters_mat(~)
            g = fullfile(getenv('HOME'), 'MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest', 'plotParameters.mat');
        end
        function g = get.plotGroupParameters_mat(~)
            g = fullfile(getenv('HOME'), 'MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest', 'plotGroupParameters.mat');
        end
    end

	methods (Test)
		function test_estimateParameters(this)
 			import mlkinetics.* mlperfusion.*;
            kf = KineticsFacade( ...
                'mcmcStrategy', PLaif1Training.load(this.ecat_fqfn, this.mask_fqfn, this.dcv_fqfn));
            kf = kf.estimateParameters;
            
            this.verifyEqual(kf.mcmcStrategy.finalMeans,  [], 'RelTol', 1e-2);
            this.verifyEqual(kf.mcmcStrategy.finalParams, [], 'RelTol', 1e-2);
            this.verifyEqual(kf.mcmcStrategy.finalStds,   [], 'RelTol', 1e-2);
        end
        function test_estimateParametersParallel(this)
            import mlkinetics.* mltraining.*;
            tf = TrainingFacade( ...
                'subjectsDir', this.subjectsDir, 'trainingFraction', 0.5);
            kpf = KineticsParallelFacade( ...
                'mcmcStrategy', PLaif1Training, ...
                'sessionPaths', tf.chpcSessionPaths, ...
                'wallTime', '02:00:00', 'memUsage', '16000', 'pool', length(tr.chpcSessionPaths)+1, ...
                'functionHandle', @KineticsFacadeParallel.estimateParameters);
            kpf = kpf.estimateParameters;
            
            this.verifyEqual(kpf.bayesianStrategies.finalMeans, []);
            this.verifyEqual(kpf.bayesianStrategies.finalParams, []);
            this.verifyEqual(kpf.bayesianStrategies.finalStds, []);
        end
        function test_plotParameters(this)
            import mlkinetics.*;
            load(this.plotParameters_mat);
            kaf = KineticsAnalysisFacade( ...
                'mcmcStrategy', kineticsFacade.mcmcStrategy);
            kaf.plotParameters;
        end
        function test_plotGroupParameters(this)
            import mlkinetics.*;
            load(this.plotGroupParameters_mat);
            kaf = KineticsAnalysisFacade( ...
                'mcmcStrategies', kineticsParallelFacade.mcmcStrategies);
            kaf.plotGroupParameters;
        end
	end

 	methods (TestClassSetup)
		function setupKineticsFacade(this)
 			import mlkinetics.*;
 			this.testObj = KineticsFacade;
 		end
	end

 	methods (TestMethodSetup)
		function setupKineticsFacadeTest(this)
            this.addTeardown(@this.cleanFiles);
 		end
    end

    %% PRIVATE
    
	properties (Access = private)
 		testObj_
    end
    
    methods (Access = private)
        function cleanFiles(this)
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

