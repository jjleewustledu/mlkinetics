classdef Test_BidsKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:30:00 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        testDir
        testFqfn
        testFqfn1
        testFqfn2
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
            this.verifyClass(obj_, "mlkinetics.BidsKit");
            this.verifyTrue(~isempty(obj_.proto_registry));
            this.verifyTrue(contains(obj_.proto_registry.keys, "ccir1211"));
            this.verifyClass(obj_.proto_registry("ccir1211"), "mlvg.Ccir1211Mediator");
            this.verifyEqual(obj_.proto_registry("ccir1211").imagingContext.fqfn, this.testFqfn);
            
            disp(obj_.proto_registry("ccir1211"))
        end
        function test_create2(this)
            obj = mlkinetics.BidsKit.create( ...
                bids_tags=["ccir1211,T1w", "ccir1211,T2w"], bids_fqfn=[this.testFqfn,this.testFqfn1]);
            this.verifyClass(obj, "mlkinetics.BidsKit");
            this.verifyEqual(obj.proto_registry.keys, {'ccir1211,T1w', 'ccir1211,T2w'});
            this.verifyClass(obj.proto_registry("ccir1211,T1w"), "mlvg.Ccir1211Mediator");
            this.verifyClass(obj.proto_registry("ccir1211,T2w"), "mlvg.Ccir1211Mediator");
            this.verifyEqual(obj.proto_registry("ccir1211,T1w").imagingContext.fqfn, this.testFqfn);
            this.verifyEqual(obj.proto_registry("ccir1211,T2w").imagingContext.fqfn, this.testFqfn1);
        end
        function test_registry(this)
            this.verifyNotEmpty(this.testObj_.proto_registry)
            med = this.testObj_.proto_registry("ccir1211");
            this.verifyNotEmpty(med)
            this.verifyEqual(med.scanPath, ...
                fullfile(getenv("HOME"), "MATLAB-Drive/mlkinetics/data/sourcedata/sub-108293/ses-20210218/anat"))
            this.verifyEqual(med.imagingContext.size(), [208 300 320])
        end
        function test_copy(this)
            this.verifyNotEmpty(this.testObj_.proto_registry)
            med_ = this.testObj_.proto_registry("ccir1211");

            this.verifyNotEmpty(this.testObj.proto_registry)
            med = this.testObj.proto_registry("ccir1211");

            this.verifyFalse(this.testObj_ == this.testObj)
            this.verifyFalse(med_ == med)
        end
        function test_make_bids_med(this)
            obj = mlkinetics.BidsKit.create( ...
                bids_tags=["ccir1211,T1w", "ccir1211,T2w"], bids_fqfn=[this.testFqfn,this.testFqfn1]);

            % install ImagingMediator
            med = obj.make_bids_med( ...
                bids_tags="ccir1211,FLAIR", ...
                bids_fqfn=this.testFqfn2);
            this.verifyEqual(obj.proto_registry.keys, {'ccir1211,FLAIR', 'ccir1211,T1w', 'ccir1211,T2w'});
            this.verifyClass(obj.proto_registry("ccir1211,FLAIR"), "mlvg.Ccir1211Mediator");
            this.verifyEqual(obj.proto_registry("ccir1211,FLAIR").imagingContext.fqfn, this.testFqfn2);
            proto = obj.proto_registry("ccir1211,FLAIR");
            this.verifyFalse(med == proto); % handles refer to distinct objects
            this.verifyTrue(isequal(med.imagingContext.fqfn, proto.imagingContext.fqfn)) % equal data contents 

            % recall ImagingMediator
            med1 = obj.make_bids_med(bids_tags="ccir1211,FLAIR");
            this.verifyEqual(obj.proto_registry.keys, {'ccir1211,FLAIR', 'ccir1211,T1w', 'ccir1211,T2w'});
            this.verifyFalse(med1 == proto); % handles refer to distinct objects
            this.verifyTrue(isequal(med1.imagingContext.fqfn, proto.imagingContext.fqfn)) % equal data contents 
        end
    end
    
    methods (TestClassSetup)
        function setupBidsKit(this)
            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            import mlkinetics.*
            this.testDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", "ses-20210218", "anat");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210218081506_T1w_MPR_vNav_4e_RMS_orient-std.nii.gz");
            this.testFqfn1 = fullfile(this.testDir, "sub-108293_ses-20210218085311_T2w_SPC_vNava.nii.gz");
            this.testFqfn2 = fullfile(this.testDir, "sub-108293_ses-20210218084611_3D_FLAIR_Sag.nii.gz");
            this.testObj_ = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.testFqfn);
        end
    end
    
    methods (TestMethodSetup)
        function setupBidsKitTest(this)
            this.testObj = copy(this.testObj_);
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
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
