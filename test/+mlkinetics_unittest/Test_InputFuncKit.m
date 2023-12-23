classdef Test_InputFuncKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:19:27 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        inputFuncFqfn
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
                
        function test_build_activity_densities(this)
            sources = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421", "pet");
            derivs = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210421", "pet");
            globbed_dyn = glob(fullfile(sources, '*dyn_pet.nii.gz'));

            import mlkinetics.*
            for g = asrow(globbed_dyn)
                pwd0 = pushd(myfileparts(g{1}));
                bk = BidsKit.create( ...
                    bids_tags="ccir1211", bids_fqfn=g{1});
                if contains(g{1}, 'fdg')
                    isotope = "18F";
                else
                    isotope = "15O";
                end
                tk = TracerKit.create( ...
                    bids_kit=bk, ...
                    ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                    tracer_tags=isotope, ...
                    counter_tags="caprac");
                sk = ScannerKit.create( ...
                    bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
                ic = sk.do_make_activity_density();
                ic.filepath = derivs;
                ic.save();
                popd(pwd0);
            end

            %pwd0 = pushd();
            %popd(pwd0);
        end
        function test_build_nifti_input_funcs(this)
            anats = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210218", "anat");
            t1w = mlfourd.ImagingContext2( ...
                fullfile(anats, "sub-108293_ses-20210218081506_T1w_MPR_vNav_4e_RMS_orient-std.nii.gz"));
            derivs = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210421", "pet");
            centerline_on_t1w = mlfourd.ImagingContext2( ...
                fullfiles(derivs, "centerline_on_T1w.nii.gz"));
            globbed_ad = glob(fullfile(derivs, '*do_make_activity_density.nii.gz'));

            for g = asrow(globbed_ad)
                pet = mlfourd.ImagingContext2(g{1});
                pet_on_t1w_fqfn = sprintf("%s_on_T1w.nii.gz", pet.fqfp);
                pet_on_t1w = mlfourd.ImagingContext2(pet_on_t1w_fqfn);
                pet_avgt = pet.timeAveraged();

                pet_avgt_on_t1w_fqfn = sprintf("%s_on_T1w.nii.gz", pet_avgt.fqfp);
                pet_avgt_on_t1w = mlfourd.ImagingContext2(pet_avgt_on_t1w_fqfn);
                pet_avgt_on_t1w_flirt = mlfsl.Flirt( ...
                    'in', pet_avgt, ...
                    'ref', t1w, ...
                    'out', pet_avgt_on_t1w, ...
                    'omat', this.mat(pet_avgt_on_t1w), ...
                    'bins', 256, ...
                    'cost', 'mutualinfo', ...
                    'dof', 6, ...
                    'interp', 'spline', ...
                    'noclobber', false);
                if ~isfile(pet_avgt_on_t1w.fqfn)
                    % do expensive coreg.
                    pet_avgt_on_t1w_flirt.flirt();
                end
                assert(isfile(pet_avgt_on_t1w.fqfn))
                pet_avgt_on_t1w.view(centerline_on_t1w)

                pet_avgt_on_t1w_flirt.in = pet;
                pet_avgt_on_t1w_flirt.out = pet_on_t1w;
                pet_avgt_on_t1w_flirt.applyXfm();

                input_func = pet_on_t1w.volumeAveraged(centerline_on_t1w);
                input_func.fileprefix =  ...
                    strrep( ...
                        strrep(pet_on_t1w.fileprefix, "_ScannerKit_do_make_activity_density", ""), ...
                        "proc-dyn", "proc-dyn-mipidif");
                input_func.addJsonMetadata(pet.json_metadata); %% refactor into Flirt 
                input_func.save();
            end
        end
        function test_caprac_kit(this)
        end
        function test_create_from_tags(this)
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %    "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421171325", "pet", ...
            %    "sub-108293_ses-20210421171325_trc-fdg_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
            %     "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "pet", ...
            %     "sub-108293_ses-20210421144815_trc-co_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", "pet", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "pet", ...
            %     "sub-108293_ses-20210421154248_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");

            pth = strrep(fileparts(bids_fqfn), "sourcedata", "derivatives");
            deleteExisting(fullfile(pth, "*proc-MipIdif*"))

            ifk = mlkinetics.InputFuncKit.create_from_tags( ...
                bids_fqfn=bids_fqfn, ...   
                bids_tags="ccir1211", ...
                scanner_tags="vision", ...
                input_func_tags="mipidif-4bolus");
            idif_ic = ifk.do_make_input_func(delete_large_files=false);
            disp(idif_ic)
            plot(idif_ic)
            idif_ic.save();
        end
        function test_ensureNumericTimingData(this)
            fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210421154248", "pet", ...
                "sub-108293_ses-20210421154248_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames-ScannerKit-do-make-activity-density_timeAppend-4_pet_MipIdif_build_aif.nii.gz");
            this.assertTrue(isfile(fqfn));
            ic = mlfourd.ImagingContext2(fqfn);
            ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(ic);
            this.assertTrue(contains(ic.fileprefix, "finite"))
            ic.save();
            
            this.assertTrue(isnumeric(ic.json_metadata.starts))
            this.assertTrue(isnumeric(ic.json_metadata.taus))
            this.assertTrue(isnumeric(ic.json_metadata.times))
            this.assertTrue(isnumeric(ic.json_metadata.timesMid))
        end
        function test_ensureTimingData(this)
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421152358', "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            med = mlvg.Ccir1211Mediator(bids_fqfn);
            j = med.json_metadata;
            this.verifyEqual(j.starts, [])
            this.verifyEqual(j.taus, 10*ones(1, 110))
            this.verifyEqual(j.times, [])
            this.verifyEqual(j.timesMid, (5:114))
            this.verifyEqual(j.timeUnit, "second")

            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421', "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-dyn_pet.nii.gz");
            med1 = mlvg.Ccir1211Mediator(bids_fqfn);
            j1 = med1.json_metadata;
            taus1 = j1.taus;
            this.verifyEqual(j1.starts, cumsum(taus1) - taus1)
            this.verifyEqual(j1.taus, taus1)
            this.verifyEqual(j1.times, cumsum(taus1) - taus1)
            this.verifyEqual(j1.timesMid, cumsum(taus1) - taus1/2)
            this.verifyEqual(j1.timeUnit, "second")
        end
        function test_estimate_recovery_coeff(this)
            sub_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293");
            scan_path = fullfile(sub_path, "ses-20210421144815", "pet");
            nii = fullfile(scan_path, ...
                "sub-108293_ses-20210421144815_trc-co_proc-BrainMoCo2-createNiftiSimple_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            idif = fullfile(scan_path, ...
                "sub-108293_ses-20210421144815_trc-co_proc-mipidif.nii.gz");
            ic = mlkinetics.InputFuncKit.estimate_recovery_coeff( ...
                scan_path=scan_path, ...
                scan_fqfn=nii, ...
                idif_fqfn=idif, ...
                tracer_tags="15O", ...
                model_tags="quadratic-martin1987");
        end
        function test_fungidif_kit(this)
        end
        function test_mipidif_kit_plot(this)
            bids_fqfn = fullfile(getenv("HOME"), ...
                "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", 'ses-20210421', "pet", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-dyn_pet.nii.gz");
            bk = mlkinetics.BidsKit.create( ...
                bids_tags="ccir1211", ...
                bids_fqfn=bids_fqfn);
            tk = mlkinetics.TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            sk = mlkinetics.ScannerKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_tags="vision");
            ifk = mlkinetics.InputFuncKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_kit=sk, ...
                input_func_tags="mipidif", ...
                input_func_fqfn="");

            dev = ifk.do_make_device();
            ic = ifk.do_make_activity_density();
            
            disp(dev)
            disp(ic)
            ifk.do_make_plot();
        end
        function test_mipidif_kit_do_make_input_func(this)
            %% alls builders of mlaif.MipIdif to create input function

            %bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %    "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
            %    "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", "pet", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames_timeAppend-4.nii.gz");
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "pet", ...
            %     "sub-108293_ses-20210421154248_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            this.assertTrue(isfile(bids_fqfn))

            tic
            bk = mlkinetics.BidsKit.create( ...
                bids_tags="ccir1211", ...
                bids_fqfn=bids_fqfn);
            toc

            tic
            tk = mlkinetics.TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="", ...
                counter_tags="caprac");
            toc

            tic
            sk = mlkinetics.ScannerKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_tags="vision");
            toc

            tic
            ifk = mlkinetics.InputFuncKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_kit=sk, ...
                input_func_tags="mipidif", ...
                input_func_fqfn="");
            toc

            tic
            ic_mipidif = ifk.do_make_input_func(steps=logical([0 0 0 1 1]), delete_large_files=false);
            toc

            tic
            disp(ic_mipidif)
            disp(ic_mipidif.json_metadata)
            plot(ic_mipidif)
            toc
        end
        function test_nifti_input_func_kit(this)
            import mlkinetics.*
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
            disp(ifk)

            ic = ifk.do_make_activity_density();
            t = asrow(ic.json_metadata.timesMid);
            rho = asrow(ic.imagingFormat.img);
            plot(t, rho)
            ylabel("activity density (Bq/mL)")
            xlabel("time (s)")
            title(stackstr(), Interpreter="none")
        end
        function test_twilite_kit(this)
            bids_fqfn = fullfile(getenv("HOME"), ...
                "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", 'ses-20210421', "pet", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-dyn_pet.nii.gz");            
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", "pet", ...
            %     "sub-108293_ses-20210421150523_trc-oo_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames_timeAppend-4.nii.gz");

            pth = strrep(fileparts(bids_fqfn), "sourcedata", "sourcedata");
            deleteExisting(fullfile(pth, "*proc-TwiliteKit*"))

            bk = mlkinetics.BidsKit.create( ...
                bids_tags="ccir1211", ...
                bids_fqfn=bids_fqfn);
            tk = mlkinetics.TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            sk = mlkinetics.ScannerKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_tags="vision");
            crv_fqfn = fullfile(getenv("HOME"), ...
                "Documents", "CCIRRadMeasurements", "Twilite", "CRV", "o15_dt20210421.crv");
            ifk = mlkinetics.InputFuncKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_kit=sk, ...
                input_func_tags="twilite-4bolus", ...
                input_func_fqfn=crv_fqfn, ...
                referenceDev=sk.do_make_device(), ...
                hct=46.8); % 46.8

            % The normal hematocrit for men is 40 to 54%; for women it is
            % 36 to 48%.  Mean = 44.5
 
            disp(ifk.do_make_device())
            ifk.do_make_plot();
            ic = ifk.do_make_activity_density();
            ic.save();

            % save with ifk.save()
            % ic.fqfn was not saved -> 
            % "/Users/jjlee/Singularity/CCIR_01211/sourcedata/sub-108293/ses-20210421150523/pet/sub-108293_ses-20210421150523_trc-oo_proc-TwiliteKit-do-make-input-func_inputfunc.nii.gz"
        end  
    end
    
    methods (TestClassSetup)
        function setupInputFuncKit(this)
            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            this.testDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet.nii.gz");
            this.inputFuncFqfn = fullfile(this.testDir, "aif_sub-108293_ses-20210421154248_trc-oo_proc-mra-mips-late.nii.gz");
        end
    end
    
    methods (TestMethodSetup)
        function setupInputFuncKitTest(this)
            %this.testObj = copy(this.testObj_);
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

    methods (Static, Access = private)
        function fn = json(obj)
            if isa(obj, 'mlfourd.ImagingContext2')
                fn = strcat(obj.fqfp, '.json');
                return
            end
            ic = mlfourd.ImagingContext2(obj);
            fn = strcat(ic.fqfp, '.json');
        end
        function fn = mat(obj)
            if isa(obj, 'mlfourd.ImagingContext2')
                fn = strcat(obj.fqfp, '.mat');
                return
            end
            ic = mlfourd.ImagingContext2(obj);
            fn = strcat(ic.fqfp, '.mat');
        end
        function fn = niigz(obj)
            if isa(obj, 'mlfourd.ImagingContext2')
                fn = strcat(obj.fqfp, '.nii.gz');
                return
            end
            ic = mlfourd.ImagingContext2(obj);
            fn = strcat(ic.fqfp, '.nii.gz');
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
