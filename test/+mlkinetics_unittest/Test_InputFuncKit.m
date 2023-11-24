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
                ic = sk.do_make_activity_density(decayCorrected=false);
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
        function test_twilite_kit(this)
            % bids_fqfn = fullfile(getenv("HOME"), ...
            %     "MATLAB-Drive", "mlkinetics", "data", "sourcedata", "sub-108293", 'ses-20210421', "pet", ...
            %     "sub-108293_ses-20210421150523_trc-oo_proc-dyn_pet.nii.gz");
            
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421", "pet", ...
                "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet.nii.gz");
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
                input_func_tags="twilite", ...
                input_func_fqfn=crv_fqfn);

            disp(ifk.do_make_device())
            ifk.do_make_activity_density();
            ifk.do_make_plot();
        end
        function test_caprac_kit(this)
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
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421152358', "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");

            tic
            bk = mlkinetics.BidsKit.create( ...
                bids_tags="ccir1211-ho", ...
                bids_fqfn=bids_fqfn);
            toc

            tic
            tk = mlkinetics.TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
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
            ic_mipidif = ifk.do_make_input_func(steps=logical([1 1 1 1]));
            toc

            tic
            plot(ic_mipidif)
            toc
        end
        function test_mipidif_kit_e7(this)
            %% using latest e7 recons

            %% create ad-hoc MRA from PET OO
            % fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523-cumul2frames", ...
            %     "sub-108293_ses-20210421150523_trc-oo_proc-BrainMoCo2-createNiftiCumul2frames-bar-alpha.nii.gz");
            % bids_ifc = mlfourd.ImagingFormatContext2(fqfn);
            % bids_ifc.img = bids_ifc.img(:,:,:,5) - bids_ifc.img(:,:,:,15);
            % bids_ifc.fileprefix = "sub-108293_ses-20210421150523_trc-oo_proc-BrainMoCo2-createNiftiCumul2frames-bar-alpha-5-15";
            % bids_ifc.save();

            % bids_fqfn__ = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421150523', "pet", ...
            %     "sub-108293_ses-20210421150523_trc-oo_proc-static_pet.nii.gz");
            % bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421150523', "pet", ...
            %     "sub-108293_ses-20210421150523_trc-oo_proc-BrainMoCo2-createNiftiMovingAvgFrames_interp1.nii.gz");

            bids_fqfn__ = fullfile(getenv("HOME"), ...
                "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", 'ses-20210421', "pet", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-static_pet.nii.gz");
            bids_fqfn = fullfile(getenv("HOME"), ...
                "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", 'ses-20210421', "pet", ...
                "");
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
            ic = ifk.do_make_activity_density(pet_avgt=bids_fqfn__, pet_mipt=bids_fqfn);
            
            disp(dev)
            disp(ic)
            ifk.do_make_plot();
        end
        function test_fungidif_kit(this)
        end
        function test_ensureTimingData(this)
            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421152358', "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            med = mlvg.Ccir1211Mediator(bids_fqfn);
            j = med.json_metadata;
            this.verifyEqual(j.start_times, 0:109)
            this.verifyEqual(j.taus, 10*ones(1, 110))
            this.verifyEqual(j.times, 0:109)
            this.verifyEqual(j.timesMid, 5:114)
            this.verifyEqual(j.timeUnit, "second")

            bids_fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", "sub-108293", 'ses-20210421', "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-dyn_pet.nii.gz");
            med1 = mlvg.Ccir1211Mediator(bids_fqfn);
            j1 = med1.json_metadata;
            taus1 = j1.taus;
            this.verifyEqual(j1.start_times, cumsum(taus1) - taus1)
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
    end
    
    methods (TestClassSetup)
        function setupInputFuncKit(this)
            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>
            this.testDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet.nii.gz");
            this.inputFuncFqfn = fullfile(this.testDir, "aif_sub-108293_ses-20210421154248_trc-oo_proc-mra-mips-late.nii.gz");

            % import mlkinetics.*
            % bk = BidsKit.create( ...
            %     bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            % tk = TracerKit.create( ...
            %     bids_kit=bk, ...
            %     ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
            %     tracer_tags="15O", ...
            %     counter_tags="caprac");
            % sk = ScannerKit.create( ...
            %     bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            % this.testObj_ = InputFuncKit.create( ...
            %     bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
            %     input_func_tags="nifti", ...
            %     input_func_fqfn=this.inputFuncFqfn);
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