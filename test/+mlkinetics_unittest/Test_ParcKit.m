classdef Test_ParcKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Jun-2023 00:29:31 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        med
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
            disp(this.testObj_)
        end
        function test_make_parc(this)
            disp(this.testObj_.make_parc())
        end
        function test_reshape_from_parc(this)
            p = this.testObj_.make_parc();
            ic1 = p.reshape_to_parc(this.med.imagingContext);
            ic = p.reshape_from_parc(ic1);
            disp(ic);
            ic.view()
        end
        function test_reshape_from_parc_ho(this)
            import mlkinetics.*

            % create template from Nick's Parcellations, to be filled with PET metric in Schaeffer's space
            targ_pth = fullfile( ...
                getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210218", "Parcellations");
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            %t1w_med = mlvg.Ccir1211Mediator.create(t1w_fqfn);
            %disp(t1w_med.imagingContext)
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-schaeffer");            
            p = pk.make_parc();
            disp(p)

            metrics_on_parc_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "derivatives", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames-ParcSchaeffer-reshape-to-schaeffer-schaeffer_dynesty-Raichle1983ModelAndArtery-RadialArtery-main5-qm.nii.gz"));
            %metrics_on_parc_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(metrics_on_parc_ic);
            med = bk.make_bids_med();
            ic1 = p.reshape_from_parc(metrics_on_parc_ic, target=med.t1w_ic);
            disp(ic1)
            ic1.view()
            ic1.save()
        end
        function test_reshape_to_parc(this)
            import mlkinetics.*
            testDir = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "pet");
            testFqfn = fullfile(testDir, "sub-108293_ses-20210421155709_trc-fdg_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames_timeAppend-165.nii.gz");
            med = mlvg.Ccir1211Mediator.create(testFqfn);
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=testFqfn);
            rk = RepresentationKit.create( ...
                representation_tags="trivial");
            testObj_ = ParcKit.create( ...
                bids_kit=bk, representation_kit=rk, parc_tags="wmparc-select-all");

            p = testObj_.make_parc();
            ic1 = p.reshape_to_parc(med.imagingContext);
            disp(ic1)
            ic1.view()
            ic1.save()
        end
        function test_schaeffer_select_all(this)
            import mlkinetics.*
            targ_pth = "/Volumes/PrecunealSSD/Singularity/CCIR_01211/derivatives/sub-108293/ses-20210218/Parcellations";
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-select-all");            
            p = pk.make_parc();
            disp(p.select_ic)
            view(p.select_ic)
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            %ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
        end
        function test_schaeffer_select_brain(this)
            import mlkinetics.*
            targ_pth = "/Volumes/PrecunealSSD/Singularity/CCIR_01211/derivatives/sub-108293/ses-20210218/Parcellations";
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-select-brain");            
            p = pk.make_parc();
            disp(p.select_ic)
            view(p.select_ic)
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            %ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
        end
        function test_schaeffer_select_gm(this)
            import mlkinetics.*
            targ_pth = "/Volumes/PrecunealSSD/Singularity/CCIR_01211/derivatives/sub-108293/ses-20210218/Parcellations";
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-select-gm");            
            p = pk.make_parc();
            disp(p.select_ic)
            view(p.select_ic)

            return
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            %ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
        end
        function test_schaeffer_select_wm(this)
            import mlkinetics.*
            targ_pth = "/Volumes/PrecunealSSD/Singularity/CCIR_01211/derivatives/sub-108293/ses-20210218/Parcellations";
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-select-wm");            
            p = pk.make_parc();
            disp(p.select_ic)
            view(p.select_ic)

            return
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            %ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
        end
        function test_schaeffer_select_subcortical(this)
            import mlkinetics.*
            targ_pth = "/Volumes/PrecunealSSD/Singularity/CCIR_01211/derivatives/sub-108293/ses-20210218/Parcellations";
            targ_fqfn = fullfile(targ_pth, "Schaefer2018_200Parcels_7Networks_order_T1_complete.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="schaeffer-select-subcortical");            
            p = pk.make_parc();
            disp(p.select_ic)
            view(p.select_ic)

            return
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            %ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
        end
        function test_wmparc_select_all(this)
            import mlkinetics.*
            targ_pth = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421152358", "pet");
            targ_fqfn = fullfile(targ_pth, "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiStatic.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="wmparc-select-all");            
            p = pk.make_parc();
            disp(p)
            
            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            ic1.filepath = targ_pth;
            disp(ic1)
            plot(ic1)
            ic1.save()
        end
        function test_wmparc_wmparc(this)
            import mlkinetics.*
            targ_pth = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421152358", "pet");
            targ_fqfn = fullfile(targ_pth, "sub-108293_ses-20210421152358_trc-ho_proc-delay0-BrainMoCo2-createNiftiStatic.nii.gz");
            bk = BidsKit.create(bids_tags="ccir1211", bids_fqfn=targ_fqfn);
            pk = ParcKit.create(bids_kit=bk, parc_tags="wmparc-wmparc");            
            p = pk.make_parc();
            disp(p)

            petdyn_ic = mlfourd.ImagingContext2( ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "pet", ...
                "sub-108293_ses-20210421152358_trc-ho_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"));
            petdyn_ic = mlpipeline.ImagingMediator.ensureFiniteImagingContext(petdyn_ic);
            ic1 = p.reshape_to_parc(petdyn_ic);
            ic1.filepath = targ_pth;
            disp(ic1)
            view(ic1)
            ic1.save()
        end
    end
    
    methods (TestClassSetup)
        function setupParcKit(this)
            % import mlkinetics.*
            % this.testDir = ...
            %     fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "derivatives", "sub-108293", "ses-20210421150523", "pet");
            % this.testFqfn = fullfile(this.testDir, "sub-108293_ses-20210421150523_trc-oo_proc-dyn_pet_ScannerKit_do_make_activity_density_on_T1w.nii.gz");
            % this.med = mlvg.Ccir1211Mediator.create(this.testFqfn);
            % bk = BidsKit.create( ...
            %     bids_tags="ccir1211", bids_fqfn=this.testFqfn);
            % rk = RepresentationKit.create( ...
            %     representation_tags="trivial");
            % this.testObj_ = ParcKit.create( ...
            %     bids_kit=bk, representation_kit=rk, parc_tags="wmparc-wmparc");
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
