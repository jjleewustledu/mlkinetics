classdef Test_KineticsViewLayer < matlab.unittest.TestCase
	%% TEST_KINETICSVIEWLAYER 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_KineticsViewLayer)
 	%          >> result  = run(mlkinetics_unittest.Test_KineticsViewLayer, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Feb-2016 22:27:40
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
        function test_viewRaw(this)
        end
        function test_viewRegistered(this)
        end
        function test_viewMasked(this)
        end
        function test_viewProjected(this)
        end
        function test_figure_idaifAndTsc(this)
        end
        function test_table_kinetics(this)
        end
        function test_(this)
        end 
        function test_(this)
        end
        function test_(this)
        end
        function test_(this)
        end 
        function test_(this)
        end
        function test_(this)
        end
        function test_(this)
        end      
	end

 	methods (TestClassSetup)
		function setupKineticsViewLayer(this)
 			import mlkinetics.*;
 			this.testObj_ = KineticsViewLayer;
 		end
	end

 	methods (TestMethodSetup)
		function setupKineticsViewLayerTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

