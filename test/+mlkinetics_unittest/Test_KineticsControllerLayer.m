classdef Test_KineticsControllerLayer < matlab.unittest.TestCase
	%% TEST_KINETICSCONTROLLERLAYER 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_KineticsControllerLayer)
 	%          >> result  = run(mlkinetics_unittest.Test_KineticsControllerLayer, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Feb-2016 22:26:14
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
        sessionData
        subjectsDir = fullfile(getenv('UNITTESTS'), 'raichle/PPGdata/idaif', '')
 		testObj
    end
    
    properties (Dependent)
        cerebrum_on_fdg
        idaif_on_fdg
    end
    
    methods %% GET
        function g = get.cerebrum_on_fdg(this)
        end
        function g = get.idaif_on_fdg(this)
        end
    end

	methods (Test)
        function test_setStudyData(this)
            study = mlpipeline.StudyDataSingletons.instance('test_raichle');
            this.fatalAssertEqual(study.subjectsDir, this.subjectsDir);
            iter = study.createIteratorForSessionData;
            sess = iter.next;
            this.fatalAssertInstanceOf(sess, 'mlpipeline.SessionData');
        end
        function test_setSessionData(this)
            sess = this.sessionData;
            this.verifyEqual(sess.fdg_fqfn, fullfile(this.subjectsDir, 'NP995_14/V1', 'NP995_14fdg.4dfp.nii.gz'));
            this.verifyEqual(sess.ho_fqfn,  fullfile(this.subjectsDir, 'NP995_14/V1', 'NP995_14ho1.4dfp.nii.gz'));
            this.verifyEqual(sess.tof_fqfn, fullfile(this.subjectsDir, 'NP995_14/V1/fdg/pet_proc', 'TOF_ART.4dfp.nii.gz'));
            this.verifyEqual(sess.T1_fqfn,  fullfile(this.subjectsDir, 'NP995_14/V1', 'T1.mgz'));
        end
        function test_createRegistered(this)
            sess = this.sessionData;
            rf   = mlfsl.RegistrationFacade('sessionData', sess);
            prod = rf.register( sess.T1, sess.petAtlas, sess.fdg);
            prod.view(sess.petAtlas, sess.fdg);
            return
            
            prod = rf.transform(sess.aparcA2009sAseg, rf.transformation(sess.T1, sess.fdg));
            prod.view(sess.petAtlas, sess.fdg);
            
            prod = rf.transform(sess.wmparc,          rf.transformation(sess.T1, sess.fdg));
            prod.view(sess.petAtlas, sess.fdg);
            
            prod = rf.register( sess.tof, sess.T1, sess.petAtlas, sess.fdg);
            prod.view(sess.petAtlas. sess.fdg);
        end
        function test_createRegionMask(this)
            sess = this.sessionData;
            sf   = mlsurfer.SurferFacade(sess);
            prod = sf.createRegionMask('cerebrum');
            prod.view(sess.petAtlas. sess.fdg);
        end
        function test_createIdaifMask(this)
            sess = this.sessionData;
            kf   = mlkinetics.KineticsFacade(sess);     
            rf   = mlfsl.RegistrationFacade(sess);
            
            rtof = kf.restrictTOF(sess.tof, sess.toffov);
            prod = rf.transform(rtof, rf.transformation(sess.tof, sess.fdg));            
            prod.view(sess.petAtlas, sess.fdg);
        end
        function test_creatProjected(this)
            sess = this.sessionData;
            kf = mlkinetics.KineticsFacade(sess);
            
            prod = kf.createProjected(sess.fdg, this.cerebrum_on_fdg);
            prod.plot;
            
            prod = kf.createProjected(sess.fdg, this.idaif_on_fdg);
            prod.plot;
        end
        function test_createIdaif(this)
        end
        function test_createTsc(this)
        end
        function test_(this)
        end

	end

 	methods (TestClassSetup)
		function setupKineticsControllerLayer(this)
 			import mlkinetics.*;
 			this.testObj_ = KineticsControllerLayer;
            this.sessionData = mlpipeline.SessionData( ...
                'studyData', mlpipeline.StudyDataSingletons.instance('test_raichle'), ...
                'sessionPath', fullfile(this.subjectsDir, 'NP995_14'), ...
                'snumber', 1, ...
                'vnumber', 1);
 		end
	end

 	methods (TestMethodSetup)
		function setupKineticsControllerLayerTest(this)
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

