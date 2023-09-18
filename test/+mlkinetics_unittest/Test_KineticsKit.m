classdef Test_KineticsKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 10:25:54 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        fqfn
        fqfn1
        fqfn_co
        fqfn_oo
        fqfn_ho
        fqfn_fdg
    end
    
    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end

        function test_BidsKit(this)
            kit = mlkinetics.BidsKit.create(bids_tags="ccir1211", bids_fqfn=this.fqfn);

            med = kit.make_bids_med(bids_fqfn=this.fqfn1);
            disp(med)
            disp(med.imagingContext)
            this.verifyTrue(contains(med.imagingContext.fileprefix, 'keepframes-4-5'))
        end
        function test_TracerKit(this)
            bk = mlkinetics.BidsKit(bids_tags="ccir1211", bids_fqfn=this.fqfn);
            tr = "[18F]FDG";
            c = "caprac";
            kit = mlkinetics.TracerKit( ...
                bids_kit=bk, tracer_tags=tr, counter_tags=c);
            r = kit.make_radionuclides();
            disp(r)
            this.verifyEqual(r.branchingRatio, 0.967)
            this.verifyEqual(r.halflife, 6586.236)
            c1 = kit.make_handleto_counter();
            disp(c1)
            r1 = kit.make_ref_source();
            disp(r1)
        end
        function test_ScannerKit(this)
            bk = mlkinetics.BidsKit(bids_tags="ccir1211", bids_fqfn=this.fqfn);
            tk = mlkinetics.TracerKit( ...
                bids_kit=bk, tracer_tags="[18F]FDG", counter_tags="caprac");
            kit = mlkinetics.ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            disp(kit)
            disp(kit.do_make_data)
            disp(kit.do_make_device)
        end
        function test_InputFuncKit(this)
            kit = mlkinetics.InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="mip_idif", input_func_fqfn="");
            disp(kit)
        end
        function test_ParcKit(this)
            kit = mlkinetics.ParcKit.create();
            disp(kit)
        end
        function test_ModelKit(this)
            bk = [];
            tk = [];
            sk = [];
            ifk = [];
            pk = [];
            data = struct([]);
            kit = mlkinetics.ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=data, model_tags="huang1980");
            disp(kit)
        end

        function test_do_make_cbv(this)
            kit = mlkinetics.KineticsKit.create( ...
                bids_fqfn=this.fqfn_co, ...
                input_func_tags="mipidif", ...
                model_tags="martin1987-quadratic");
            cbv = kit.do_make_cbv();
            cbv.view();
        end
        function test_do_make_cbf(this)
            kit = mlkinetics.KineticsKit.create( ...
                bids_fqfn=this.fqfn_ho, ...
                input_func_tags="mipidif", ...
                model_tags="raichle1983-quadratic");
            cbf = kit.do_make_cbf();
            cbf.view_qc();
        end
        function test_do_make_oef(this)
            kit = mlkinetics.KineticsKit.create();
            oef = kit.do_make_oef();
            oef.view_qc();
        end
        function test_do_make_cmro2(this)
            kit = mlkinetics.KineticsKit.create();
            cmro2 = kit.do_make_cmro2();
            cmro2.view_qc();
        end
        function test_do_make_cmrglc(this)
            kit = mlkinetics.KineticsKit.create();
            cmrglc = kit.do_make_cmrglc();
            cmrglc.view_qc();
        end
        function test_do_make_agi(this)
            kit = mlkinetics.KineticsKit.create();
            agi = kit.do_make_agi();
            agi.view_qc();
        end
        
        function test_do_make_1tcm(this)
        end
        function test_do_make_2tcm(this)
        end
        function test_do_make_ichise_ma(this)
        end
        function test_do_make_prga(this)
        end
        function test_do_make_rtga(this)
        end
        function test_do_make_srtm(this)
        end
    end
    
    methods (TestClassSetup)
        function setupKineticsKit(this)
            this.fqfn = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421171325_trc-fdg_proc-static-phantom_pet.nii.gz');
            this.fqfn1 = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421155709_trc-fdg_proc-dyn_pet_keepframes-4-5_avgt_b25.nii.gz');
            this.fqfn_co = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421144815_trc-oc_proc-dyn_pet_on_T1w.nii.gz');
            this.fqfn_oo = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421154248_trc-oo_proc-dyn_pet_on_T1w.nii.gz');
            this.fqfn_ho = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421152358_trc-ho_proc-dyn_pet_on_T1w.nii.gz');
            this.fqfn_fdg = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_01211/derivatives/sub-108293/ses-20210421/pet', ...
                'sub-108293_ses-20210421155709_trc-fdg_proc-dyn_pet_on_T1w.nii.gz');
        end
    end
    
    methods (TestMethodSetup)
        function setupKineticsKitTest(this)
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
