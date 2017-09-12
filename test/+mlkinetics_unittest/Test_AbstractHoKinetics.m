classdef Test_AbstractHoKinetics < matlab.unittest.TestCase
	%% TEST_ABSTRACTHOKINETICS 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_AbstractHoKinetics)
 	%          >> result  = run(mlkinetics_unittest.Test_AbstractHoKinetics, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 17-Jul-2017 12:58:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        hyglyNN = 'HYGLY28'
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
        function test_ctor(this)
        end
        function test_aif(this)
            this.verifyClass(this.testObj.aif, 'mlpet.Twilite');
        end
        function test_scanner(this)
            this.verifyClass(this.testObj.scanner, 'mlsiemens.BiographMMR');
        end
	end

 	methods (TestClassSetup)
		function setupAbstractHoKinetics(this)
 			import mlraichle.*;
            studyd = StudyData;
            sessp  = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            sessd  = SessionData('studyData', studyd, 'sessionPath', sessp, 'tracer', 'HO', 'ac', true);
 			this.testObj_ = HoKinetics('sessionData', sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupAbstractHoKineticsTest(this)
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

