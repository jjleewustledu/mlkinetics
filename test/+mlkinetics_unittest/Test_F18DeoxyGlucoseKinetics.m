classdef Test_F18DeoxyGlucoseKinetics < matlab.unittest.TestCase
	%% TEST_F18DEOXYGLUCOSEKINETICS 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_F18DeoxyGlucoseKinetics)
 	%          >> result  = run(mlkinetics_unittest.Test_F18DeoxyGlucoseKinetics, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Jan-2016 16:55:57
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
        sessionData
 		testObj
 	end

	methods (Test)
		function test_runPowers(this)
            studyd = mlpipeline.StudyDataSingletons.instance('test_powers');
            sessd = studyd.sessionData('studyData', studyd, 'sessionPath', pwd);
            [~,kmin,k1k3overk2k3] = mlkinetics.F18DeoxyGlucoseKinetics.runPowers(sessd);
            
            verifyEqual(kmin, [ 0.045294 0.010439 0.010606 0.000003 ], 'RelTol', 1e-4);
            verifyEqual(k1k3overk2k3, 1.36960975513824, 'RelTol', 1e-4);
        end
        function test_disp(this)
            disp(this.testObj);
        end
        function test_estimateParameters(this)
        end
        function test_plotParVars(this)
        end
        function test_simulateMcmc(this)
        end
        function test_wholebrain(this)
        end
	end

 	methods (TestClassSetup)
		function setupF18DeoxyGlucoseKinetics(this)
 			import mlkinetics.*;
            studyData = mlpipeline.StudyDataSingletons.instance('test_powers');
            iter = studyData.createIteratorForSessionData;
            this.sessionData = iter.next;
 			this.testObj_ = F18DeoxyGlucoseKinetics(this.sessionData);
 		end
	end

 	methods (TestMethodSetup)
		function setupF18DeoxyGlucoseKineticsTest(this)
 			this.testObj = this.testObj_;
 		end
	end

	properties (Access = 'private')
 		testObj_
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

