classdef Test_KineticsModelLayer < matlab.unittest.TestCase
	%% TEST_KINETICSMODELLAYER 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_KineticsModelLayer)
 	%          >> result  = run(mlkinetics_unittest.Test_KineticsModelLayer, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 12-Jan-2016 19:08:53
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
        function test_estimateParameters(this)
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
        function test_(this)
        end
	end

 	methods (TestClassSetup)
		function setupKineticsModelLayer(this)
 			import mlkinetics.*;
 			this.testObj_ = KineticsModelLayer;
 		end
	end

 	methods (TestMethodSetup)
		function setupKineticsModelLayerTest(this)
 			this.testObj = this.testObj_;
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

