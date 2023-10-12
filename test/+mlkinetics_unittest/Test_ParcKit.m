classdef Test_ParcKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:29:31 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        testDir
        testFqfn
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
    end
    
    methods (TestClassSetup)
        function setupParcKit(this)
            import mlkinetics.*
            this.testDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            rk = RepresentationKit.create( ...
                representation_tags="trivial");
            this.testObj_ = ParcKit.create( ...
                bids_kit=bk, representation_kit=rk, parc_tags="wmparc");
        end
    end
    
    methods (TestMethodSetup)
        function setupParcKitTest(this)
            this.testObj = this.testObj_;
            this.addTeardown(@this.cleanTestMethod)
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
