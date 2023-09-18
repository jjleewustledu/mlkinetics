classdef Test_ScannerKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:19:35 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
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
        function test_do_make_device(this)   
            dev = this.testObj.do_make_device();
            this.verifyTrue(dev.calibrationAvailable)
            this.verifyEqual(dev.invEfficiency, 1.087017298092194, RelTol=1e-6)
            this.verifyTrue(dev.decayCorrected)
            this.verifyEqual(dev.halflife, 6.586236e+03, RelTol=1e-6)
            this.verifyEqual(dev.isotope, '18F')
            this.verifyClass(dev.radMeasurements, "mlpet.CCIRRadMeasurements")
            this.verifyEqual(dev.tracer, "FDG")
            this.verifyEqual(dev.datetime0, datetime("21-Apr-2021 15:56:38", TimeZone="local"))
            this.verifyEqual(dev.datetimeF, datetime("21-Apr-2021 16:51:38", TimeZone="local"))
            this.verifyEqual(dev.dt, 1)
            this.verifyEqual(dev.index0, 1)
            this.verifyEqual(dev.indexF, 52)
            this.verifyEqual(dev.indices(1:3), [1 2 3])
            this.verifyEqual(dev.taus(1:3), [5 5 5])
            this.verifyEqual(dev.time0, 0)
            this.verifyEqual(dev.timeF, 3300)
            this.verifyEqual(dev.timeInterpolants(1:3), [0 1 2])
            this.verifyEqual(dev.times(1:3), [0 5 10])
            this.verifyEqual(dev.timesMid(1:3), [2.5 7.5 12.5])
            this.verifyEqual(dev.timeWindow, 3300)
            this.verifyTrue(contains(dev.fileprefix, "mlsiemens_BiographVisionDevice"))            
        end
        function test_do_make_activity_density(this)            
            ic = this.testObj.do_make_activity_density();
            this.verifyEqual(ic.fileprefix, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn_pet_ScannerKit_do_make_activity_density")
            this.verifyEqual(ic.filesuffix, ".nii.gz")
            this.verifyEqual(ic.noclobber, false)
            this.verifyEqual(ic.bytes, 3.201369672000000e+09, RelTol=1e-6)
            this.verifyEqual(ic.compatibility, false)
            this.verifyClass(ic.json_metadata, "struct")
            this.verifyClass(ic.logger, "mlpipeline.Logger2")
            this.verifyEqual(ic.orient, 'RADIOLOGICAL')
            this.verifyEqual(ic.qfac, -1)
            this.verifyEqual(ic.stateTypeclass, 'mlfourd.MatlabTool')
            this.verifyClass(ic.viewer, "mlfourd.Viewer")
        end
        function test_json_metadata(this)       
            ic = this.testObj.do_make_activity_density();
            j = ic.json_metadata;
            this.verifyEqual(j.taus(1:5), [5 5 5 5 5])
            this.verifyEqual(j.times(1:5), [0 5 10 15 20])
            this.verifyEqual(j.timesMid(1:5), [2.5 7.5 12.5 17.5 22.5])
            this.verifyEqual(j.timeUnit, "second")
        end
        function test_vis(this)
            this.testObj.do_make_plot();
            this.testObj.do_make_view();            
        end
    end
    
    methods (TestClassSetup)
        function setupScannerKit(this)
            import mlkinetics.*

            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            import mlkinetics.*
            this.testDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn_pet.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="18F", ...
                counter_tags="caprac");
            this.testObj_ = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
        end
    end
    
    methods (TestMethodSetup)
        function setupScannerKitTest(this)
            this.testObj = copy(this.testObj_);
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
