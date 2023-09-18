classdef Test_ModelKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:19:00 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        inputFuncFqfn
        testDir
        testFqfn
        testObj
        tracer_kit
    end
    
    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_tracer_kit(this)
            disp(this.tracer_kit.proto_registry('caprac'))
        end
        function test_create(this)
            disp(this.testObj_)
            disp(this.testObj_.proto_registry("quadratic-martin1987"))
        end

        %% alternatives to this.testObj

        function test_raiche1983_make_solution(this)
            import mlkinetics.*
            testFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            inputFuncFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn-mipidif_pet_on_T1w.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=testFqfn__);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=inputFuncFqfn__);
            pk = [];
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct([]), ...
                model_tags="quadratic-raichle1983");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_martin1987_make_solution(this)
            sol = this.testObj_.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_mintun1984_make_solution(this)
            import mlkinetics.*
            testFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            inputFuncFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn-mipidif_pet_on_T1w.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=testFqfn__);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=inputFuncFqfn__);
            pk = [];
            cbf_ic = mlfourd.ImagingContext2( ...
                fullfile(this.testDir, "sub-108293_ses-20210421152358_cbf_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz"));
            cbv_ic = mlfourd.ImagingContext2( ...
                fullfile(this.testDir, "sub-108293_ses-20210421144815_cbv_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz"));
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct("cbf_ic", cbf_ic, "cbv_ic", cbv_ic), ...
                model_tags="quadratic-mintun1984");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_huang1980_make_solution(this)
            import mlkinetics.*
            testFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            inputFuncFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn-mipidif_pet_on_T1w.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=testFqfn__);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="18F", ...
                counter_tags="caprac");
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=inputFuncFqfn__);
            pk = [];
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct([]), ...
                model_tags="huang1980");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
    end
    
    methods (TestClassSetup)
        function setupModelKit(this)
            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            import mlkinetics.*
            this.testDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            this.inputFuncFqfn = fullfile(this.testDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn-mipidif_pet_on_T1w.nii.gz");
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.inputFuncFqfn);
            pk = [];
            this.testObj_ = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct([]), ...
                model_tags="quadratic-martin1987");
            this.tracer_kit = tk;
        end
    end
    
    methods (TestMethodSetup)
        function setupModelKitTest(this)
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
