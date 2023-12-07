classdef Test_Model < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 21-Nov-2023 15:00:56 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties
        enclaveAnatDir
        dlicv_ic

        enclavePetDir
        co_ic
        fdg_ic
        ho_ic        
        oo_ic
        co_mipidif_ic % mip idif without amplitude filter, recovery coeff ~ 1
        fdg_mipidif_ic
        ho_mipidif_ic % mip idif without amplitude filter, recovery coeff ~ 2
        oo_mipidif_ic % mip idif without amplitude filter, recovery coeff ~ 2

        cbf_ic % from twilite
        cbv_ic % from twilite
        oef_ic % from twilite
        cmro2_ic % from twilite
        cmrglc_ic % from caprac
        raichleks_ic 

        bk % for this.co_ic
        ifk % for this.co_mipidif_ic
        rk
        pk
        sk
        tk
    end
    
    methods (Test)
        function test_afun(this)            
            
            disp(this.enclavePetDir)

            import mlkinetics.*
            this.assumeEqual(0:9,(0:9));
            this.verifyEqual(0:9,(0:9));
            this.assertEqual(0:9,(0:9));
        end
        function test_class_setup(this)
            tic

            this.verifyTrue(isfile(this.dlicv_ic.fqfn))
            this.verifyTrue(isfile(this.co_mipidif_ic.fqfn))
            this.verifyTrue(isfile(this.oo_mipidif_ic.fqfn))
            this.verifyTrue(isfile(this.ho_mipidif_ic.fqfn))

            this.verifyTrue(isfile(this.co_ic.fqfn))
            this.verifyTrue(isfile(this.ho_ic.fqfn))
            this.verifyTrue(isfile(this.oo_ic.fqfn))

            this.verifyTrue(isfile(this.cbf_ic.fqfn))
            this.verifyTrue(isfile(this.cbv_ic.fqfn))
            this.verifyTrue(isfile(this.oef_ic.fqfn))
            this.verifyTrue(isfile(this.cmro2_ic.fqfn))

            disp(this.bk)
            disp(this.tk)
            disp(this.sk)
            disp(this.ifk)
            disp(this.pk)
            
            fprintf(stackstr()+": ")
            toc
        end
        function test_view_dynamic(this)
            co_ic_ = this.co_ic.volumeAveraged(this.dlicv_ic);
            figure; plot(co_ic_);
            hold on; plot(this.co_mipidif_ic); hold off;
            legend([string(co_ic_.fileprefix), string(this.co_mipidif_ic.fileprefix)], Interpreter="none");

            oo_ic_ = this.oo_ic.volumeAveraged(this.dlicv_ic);
            figure; plot(oo_ic_);
            hold on; plot(this.oo_mipidif_ic); hold off;
            legend([string(oo_ic_.fileprefix), string(this.oo_mipidif_ic.fileprefix)], Interpreter="none");

            ho_ic_ = this.ho_ic.volumeAveraged(this.dlicv_ic);
            figure; plot(ho_ic_);
            hold on; plot(this.ho_mipidif_ic); hold off;
            legend([string(ho_ic_.fileprefix), string(this.ho_mipidif_ic.fileprefix)], Interpreter="none");
        end
        function test_rescale_mipidif(this)
            ic = this.co_mipidif_ic;
            fp = ic.fileprefix;
            fp = strrep(fp, "mtimes_2", "mtimes_4");
            fprintf("%s:\n", ic.fileprefix)
            dipmax(ic)
            ic = ic * 2;
            dipmax(ic)
            ic.fileprefix = fp;
            ic.save();

            ic = this.oo_mipidif_ic;
            fp = ic.fileprefix;
            fp = strrep(fp, "mtimes_2", "mtimes_4");
            fprintf("%s:\n", ic.fileprefix)
            dipmax(ic)
            ic = ic * 2;
            dipmax(ic)
            ic.fileprefix = fp;
            ic.save();

            ic = this.ho_mipidif_ic;
            fp = ic.fileprefix;
            fp = strrep(fp, "mtimes_2", "mtimes_4");
            fprintf("%s:\n", ic.fileprefix)
            dipmax(ic)
            ic = ic * 2;
            dipmax(ic)
            ic.fileprefix = fp;
            ic.save();
        end
        function test_Martin1987Model(this)
            import mlkinetics.*
            this.bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.co_ic.fqfn);
            this.tk = TracerKit.create( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            this.sk = ScannerKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_tags="nifti");
            this.ifk = InputFuncKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.co_mipidif_ic.fqfn);
            this.rk = RepresentationKit.create( ...
                representation_tags="trivial");   
            this.pk = [];

            mk = ModelKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, input_func_kit=this.ifk, representation_kit=this.rk, parc_kit=this.pk, ...
                data=[], ...
                model_tags="martin1987");  
            disp(mk)
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_Raichle1983Model(this)
            import mlkinetics.*
            this.bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.ho_ic.fqfn);
            this.tk = TracerKit.create( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            this.sk = ScannerKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_tags="nifti");
            this.ifk = InputFuncKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.ho_mipidif_ic.fqfn);
            this.rk = RepresentationKit.create( ...
                representation_tags="trivial");   
            this.pk = ParcKit.create( ...
                bids_kit=this.bk, representation_kit=this.rk, parc_tags="wmparc-wmparc");

            mk = ModelKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, input_func_kit=this.ifk, representation_kit=this.rk, parc_kit=this.pk, ...
                data=struct("cbv_ic", this.cbv_ic), ...
                model_tags="raichle1983-simulanneal");  
            disp(mk)
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_Mintun1984Model(this)
            import mlkinetics.*
            this.bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.oo_ic.fqfn);
            this.tk = TracerKit.create( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="15O", ...
                counter_tags="caprac");
            this.sk = ScannerKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_tags="nifti");
            this.ifk = InputFuncKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.oo_mipidif_ic.fqfn);    
            this.rk = RepresentationKit.create( ...
                representation_tags="trivial");   
            this.pk = ParcKit.create( ...
                bids_kit=this.bk, representation_kit=this.rk, parc_tags="wmparc-wmparc");

            mk = ModelKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, input_func_kit=this.ifk, representation_kit=this.rk, parc_kit=this.pk, ...
                data=struct("cbv_ic", this.cbv_ic, "raichleks_ic", this.raichleks_ic), ...
                model_tags="mintun1984-simulanneal");  
            disp(mk)
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
        function test_Huang1980Model(this)
            import mlkinetics.*
            this.bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=this.fdg_ic.fqfn);
            this.tk = TracerKit.create( ...
                bids_kit=this.bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags="18F", ...
                counter_tags="caprac");
            this.sk = ScannerKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_tags="nifti");
            this.ifk = InputFuncKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=this.fdg_mipidif_ic.fqfn);    
            this.rk = RepresentationKit.create( ...
                representation_tags="trivial");   
            this.pk = ParcKit.create( ...
                bids_kit=this.bk, representation_kit=this.rk, parc_tags="wmparc-wmparc");

            mk = ModelKit.create( ...
                bids_kit=this.bk, tracer_kit=this.tk, scanner_kit=this.sk, input_func_kit=this.ifk, representation_kit=this.rk, parc_kit=this.pk, ...
                data=struct("cbv_ic", this.cbv_ic), ...
                model_tags="huang1980-simulanneal");
            disp(mk)
            sol = mk.make_solution();
            disp(sol)
            sol.view()
            sol.save()
        end
    end
    
    methods (TestClassSetup)
        function setupModel(this)
            import mlkinetics.*

            tic 
            warning("off", "mfiles:ChildProcessWarning"); %#ok<WNTAG>

            this.enclaveAnatDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210218", "anat");
            this.dlicv_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclaveAnatDir, "sub-108293_ses-20210218081506_T1w_MPR_vNav_4e_RMS_orient-std_DLICV.nii.gz"));

            this.enclavePetDir = ...
                fullfile(getenv("HOME"), "MATLAB-Drive", "mlkinetics", "data", "derivatives", "sub-108293", "ses-20210421", "pet");
            this.co_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn-ScannerKit-do-make-activity-density_pet_on_T1w.nii.gz"));
            this.co_mipidif_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn-mipidif_pet_on_T1w_mtimes_2.nii.gz"));
            this.oo_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn-ScannerKit-do-make-activity-density_pet_on_T1w.nii.gz"));
            this.oo_mipidif_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn-mipidif_pet_on_T1w_mtimes_2.nii.gz"));
            this.ho_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn-ScannerKit-do-make-activity-density_pet_on_T1w.nii.gz"));
            this.ho_mipidif_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn-mipidif_pet_on_T1w_mtimes_2.nii.gz"));
            this.cbf_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn_cbf_on_T1w_voxels.nii.gz"));
            this.cbv_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421144815_trc-oc_proc-dyn_cbv_on_T1w_voxels.nii.gz"));
            this.oef_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421154248_trc-oo_proc-dyn_oef_on_T1w_voxels.nii.gz"));
            this.cmro2_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421150523_trc-oo_proc-dyn_cmro2-umol_on_T1w_voxels.nii.gz"));
            this.raichleks_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421152358_trc-ho_proc-dyn-ScannerKit-do-make-activity-density_ks_on_T1w_ParcWmparc_reshape_from_parc.nii.gz"));
            this.fdg_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn-ScannerKit-do-make-activity-density_pet_on_T1w.nii.gz"));
            this.fdg_mipidif_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421155709_trc-fdg_proc-dyn-mipidif_pet_on_T1w_mtimes_2.nii.gz"));
            this.cmrglc_ic = mlfourd.ImagingContext2( ...
                fullfile(this.enclavePetDir, "sub-108293_ses-20210421155638_cmrglc-umol_proc-dyn_pet_on_T1w_wmparc1"));

            this.pk = [];

            fprintf(stackstr()+": ")
            toc
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
