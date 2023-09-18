classdef Test_TracerKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 13-Jul-2023 02:36:09 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2286388 (R2023a) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        bk
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
        function test_create(this)
            obj_ = this.testObj_;
            this.verifyClass(obj_, "mlkinetics.TracerKit");
            this.verifyTrue(~isempty(obj_.proto_registry));
            this.verifyTrue(contains(obj_.proto_registry.keys, "caprac"));
            this.verifyClass(obj_.proto_registry("caprac"), "mlpet.CCIRRadMeasurements");
            this.verifyEqual(obj_.proto_registry("caprac").clocks{1,1}, 31);
            
            disp(obj_.proto_registry("caprac"))
        end
        function test_make_handleto_counter(this)
            obj = this.testObj;

            % install counter
            cnt = obj.make_handleto_counter( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="18F", ...
                counter_tags="caprac2");
            this.verifyEqual(obj.proto_registry.keys, {'caprac', 'caprac2'});
            this.verifyClass(obj.proto_registry("caprac"), "mlpet.CCIRRadMeasurements");
            this.verifyEqual(obj.proto_registry("caprac").clocks{1,1}, 31);
            proto = obj.proto_registry("caprac");
            this.verifyFalse(cnt == proto); % handles refer to distinct objects
            this.verifyTrue(isequal(cnt.clocks, proto.clocks)) % equal data contents 

            % recall counter
            cnt1 = obj.make_handleto_counter(counter_tags="caprac2");
            this.verifyEqual(obj.proto_registry.keys, {'caprac', 'caprac2'});
            this.verifyFalse(cnt1 == proto); % handles refer to distinct objects
            this.verifyTrue(isequal(cnt1.clocks, proto.clocks)) % equal data contents 
        end
    end
    
    methods (TestClassSetup)
        function setupTracerKit(this)
            import mlkinetics.*

            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            import mlkinetics.*
            this.testDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421162709_trc-fdg_proc-static_pet.nii.gz");
            this.bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            this.testObj_ = TracerKit.create( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="18F", ...
                counter_tags="caprac");
        end
    end
    
    methods (TestMethodSetup)
        function setupTracerKitTest(this)
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
