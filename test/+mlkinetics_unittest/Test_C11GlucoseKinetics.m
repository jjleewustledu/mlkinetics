classdef Test_C11GlucoseKinetics < matlab.unittest.TestCase
	%% TEST_C11GLUCOSEKINETICS 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_C11GlucoseKinetics)
 	%          >> result  = run(mlkinetics_unittest.Test_C11GlucoseKinetics, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Jan-2016 16:56:18
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlkinetics.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
	end

 	methods (TestClassSetup)
		function setupC11GlucoseKinetics(this)
 			import mlkinetics.*;
 			this.testObj_ = C11GlucoseKinetics;
 		end
	end

 	methods (TestMethodSetup)
		function setupC11GlucoseKineticsTest(this)
 			this.testObj = this.testObj_;
 		end
	end

	properties (Access = 'private')
 		testObj_
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

