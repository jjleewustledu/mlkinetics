classdef Test_ModelKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:19:00 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        enclaveAnatDir
        enclavePetDir
        ocMipidifFqfn
        ocFqfn
        testDir
        testObj
        tracer_15o_kit
    end
    
    properties (Dependent)
        enclaveCbf % quadratic raichle
        enclaveCbv % quadratic martin
        enclaveCenterlineOnOo1 % mips
        enclaveDlicv
        enclaveOo1 % scanner reconstructions
    end

    methods %% GET
        function g = get.enclaveCbf(this)
            g = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421152358_cbf_proc-dyn_pet_on_T1w_voxels.nii.gz"));
        end
        function g = get.enclaveCbv(this)
            g = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421144815_cbv_proc-dyn_pet_on_T1w_voxels.nii.gz"));
        end
        function g = get.enclaveCenterlineOnOo1(this)
            g = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "centerline_on_20210421150523.nii.gz"));
        end
        function g = get.enclaveDlicv(this)
            g = mlfourd.ImagingContext2( ...
                fullfile(this.enclaveAnatDir, "sub-108293_ses-20210218081506_T1w_MPR_vNav_4e_RMS_orient-std_DLICV.nii.gz"));
        end
        function g = get.enclaveOo1(this)
            g = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421150523_trc-oo_proc-dyn_pet_ScannerKit_do_make_activity_density.nii.gz"));
        end
    end

    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_create(this)
            disp(this.testObj_)
            disp(this.testObj_.proto_registry("quadratic-martin1987"))
        end
        function test_empty(this)
            disp(stackstr())
        end
        function test_enclave(this)
            E_cbv_wb = this.enclaveCbv.volumeAveraged(this.enclaveDlicv);
            E_cbv_wb = double(E_cbv_wb);
            this.verifyEqual(E_cbv_wb, 5.201992034912109, RelTol=1e-15)

            E_cbf_wb = this.enclaveCbf.volumeAveraged(this.enclaveDlicv);
            E_cbf_wb = double(E_cbf_wb);
            this.verifyEqual(E_cbf_wb, 40.853492736816406, RelTol=1e-15)
        end
        function test_solutionOnScannerFrames(this)
            q1 = mlkinetics.Raichle1983Model.solutionOnScannerFrames(5:114, 5:114);
            this.verifyEqual(q1, 5:114);
            taus = [10 10 14 14 22 22];
            times_sampled = cumsum(taus) - taus/2; % ~ timesMid
            q1 = mlkinetics.Raichle1983Model.solutionOnScannerFrames(5:114, times_sampled);
            this.verifyEqual(q1, times_sampled, RelTol=0.01);
        end
        function test_tracer_kit(this)
            disp(this.tracer_15o_kit.proto_registry('caprac'))
        end

        %% alternatives to this.testObj

        function test_raiche1983_make_solution_quadratic(this)
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
                data=struct(), ...
                model_tags="quadratic-raichle1983");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_raiche1983_make_solution_simulanneal(this)
            import mlkinetics.*
            workdir = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211/derivatives/sub-108293/ses-20210421152358", "pet");
            pwd0 = pushd(workdir);

            testFqfn__ = fullfile(workdir, ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            inputFuncFqfn__ = fullfile(workdir, ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames_ScannerKit_do_make_activity_density_MipIdif_build_aif.nii.gz");
 
            tic
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=testFqfn__);
            fprintf(stackstr()+": ")
            toc
            
            tic
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
            rk = RepresentationKit.create( ...
                representation_tags="trivial");            
            pk = ParcKit.create( ...
                bids_kit=bk, representation_kit=rk, parc_tags="wmparc-wmparc");
            fprintf(stackstr()+": ")
            toc

            cbv = mlfourd.ImagingContext2( ...
                fullfile(workdir, "sub-108293_ses-20210421144815_cbv_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz"));
            cbv = cbv.uthresh(100);
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, representation_kit=rk, parc_kit=pk, ...
                data=struct(cbv=cbv), ...
                model_tags="raichle1983-simulanneal");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()

            popd(pwd0);
        end
        function test_martin1987_make_solution(this)
            sol = this.testObj_.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_mintun1984_mipidif_make_solution(this)
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
                input_func_fqfn=inputFuncFqfn__, ...
                recovery_coeff=2);
            pk = [];
            cbf_ic = this.enclaveCbf;
            cbv_ic = this.enclaveCbv;
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct("cbf_ic", cbf_ic, "cbv_ic", cbv_ic), ...
                model_tags="quadratic-mintun1984");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_mintun1984_twilite_make_solution(this)
            import mlkinetics.*
            testFqfn__ = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
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
                input_func_tags="twilite");
            pk = [];
            cbf_ic = this.enclaveCbf;
            cbv_ic = this.enclaveCbv;
            data = struct("cbf_ic", cbf_ic, "cbv_ic", cbv_ic);
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=data, ...
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
            cbf_ic = this.enclaveCbf;
            cbv_ic = this.enclaveCbv;
            data = struct("cbf_ic", cbf_ic, "cbv_ic", cbv_ic);
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=data, ...
                model_tags="huang1980");            
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_dynesty(this)
            import mlkinetics.*

            sourcedataDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet");
            derivativesDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421152358", "pet");
            cbvDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421144815", "pet");
            hoFqfn = ...
                fullfile(sourcedataDir, "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            hoMipidifFqfn = ...
                fullfile(derivativesDir, "sub-108293_ses-20210421152358_trc-ho_proc-MipIdif_idif_dynesty-Boxcar-ideal.nii.gz");
            martinv1Fqfn = ...
                fullfile(cbvDir, "sub-108293_ses-20210421144815_martinv1_on_ho.nii.gz");

            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=hoFqfn);
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
                input_func_fqfn=hoMipidifFqfn);
            pk = ParcKit.create( ...
                bids_kit=bk, parc_tags="wmparc-wmparc");
            martinv1_ic = mlfourd.ImagingContext2(martinv1Fqfn);
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct("martinv1_ic", martinv1_ic), ...
                model_tags="dynesty-idif-raichle1983");
            sol = mk.make_solution();            
            disp(sol)
            sol.view()
            sol.save()
        end
    end
    
    methods (TestClassSetup)
        function setupModelKit(this)
            tic 

            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            import mlkinetics.*

            this.enclaveAnatDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210218", "anat");
            this.enclavePetDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210421", "pet");
            
            this.testDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.ocFqfn = ...
                fullfile(this.testDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            this.ocMipidifFqfn = ...
                fullfile(this.testDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn-mipidif_pet_on_T1w.nii.gz");
            
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.ocFqfn);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            this.tracer_15o_kit = tk;
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.ocMipidifFqfn);
            pk = [];
            this.testObj_ = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct(), ...
                model_tags="quadratic-martin1987");

            fprintf(stackstr()+": ")
            toc
        end
    end
    
    methods (TestMethodSetup)
        function setupModelKitTest(this)
            if ~isempty(this.testObj_)
                this.testObj = copy(this.testObj_);
            end
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
