classdef Test_MultiBolusTiming < matlab.unittest.TestCase
	%% TEST_MULTIBOLUSTIMING 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_MultiBolusTiming)
 	%          >> result  = run(mlkinetics_unittest.Test_MultiBolusTiming, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Nov-2018 18:12:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
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
		function setupMultiBolusTiming(this)
 			import mlkinetics.*;
 			this.testObj_ = MultiBolusTiming;
 		end
	end

 	methods (TestMethodSetup)
		function setupMultiBolusTimingTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

