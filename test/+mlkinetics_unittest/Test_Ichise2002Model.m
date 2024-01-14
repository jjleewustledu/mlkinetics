classdef Test_Ichise2002Model < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 14-Dec-2023 11:31:34 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_build_simulated(this)
            obj = mlkinetics.Ichise2002Model.create();
            measurement_ = [ ...
                0,220,350,400,415,440,470,495,500,498, ...
                490,485,470,452,434,418,404,392,381,370, ...
                360,350,340,330,321,312,303,294,285,277, ...
                269,261,253]*1e3; % Bq/mL
            T = this.table_mc_ptac_ro948(max(measurement_));

            taus = [0.5*ones(1,10), 5*ones(1,23)]*60;
            obj.set_times_sampled(cumsum(taus) - taus/2); % sec
            obj.set_artery_interpolated(makima(T.Sec, 30*T.Bq_mL_pTAC, 0:120*60));
            obj.Data = struct( ...
                'measurement_sampled', measurement_, ...
                'times', cumsum(taus) - taus, ...
                'taus', taus);
            ks = [0.8542/60, 0.0785/60, 0.0502/60, 0.0227/60, 1, 1];
            tac = obj.build_simulated(ks);
            figure; plot(obj.times_sampled, tac)
        end
        function test_build_mdl(this)
            obj = mlkinetics.Ichise2002Model.create();
            measurement_ = [ ...
                0,220,350,400,415,440,470,495,500,498, ...
                490,485,470,452,434,418,404,392,381,370, ...
                360,350,340,330,321,312,303,294,285,277, ...
                269,261,253]*1e3; % Bq/mL
            T = this.table_mc_ptac_ro948(max(measurement_));
            taus = [0.5*ones(1,10), 5*ones(1,23)]*60;

            obj.set_times_sampled(cumsum(taus) - taus/2); % sec
            obj.set_artery_interpolated(makima(T.Sec, 30*T.Bq_mL_pTAC, 0:120*60));
            obj.Data = struct( ...
                'measurement_sampled', measurement_, ...
                'times', cumsum(taus) - taus, ...
                'taus', taus);
            %ks = [0.8542/60, 0.0785/60, 0.0502/60, 0.0227/60, 1, 1];
            obj.build_model( ...
                map=obj.preferredMap_mdl, ...
                measurement=measurement_);
            obj.solver = obj.solver.solve(@mlkinetics.Ichise2002Model.loss_function);
            obj.solver.plot(tag=stackstr(), zoomMeas=8, zoomModel=8, xlim=[-10, 3600]);
        end
        function test_TZ3108_build_multinest(this)
            % fqfn = fullfile( ...
            %     "/Volumes/T7 Shield/TZ3108/sub-lou/ses-20230406/chemistry", ...
            %     "sub-lou_ses-20230406_pkin-recalib2.kmData.xls");
            fqfn = fullfile( ...
                "/Volumes/T7 Shield/TZ3108/sub-bud/ses-20140724/chemistry", ...
                "sub-bud_ses-20140724_pkin.kmData.xls");
            tz = mlwong.TZ3108.create(fqfn);
            tz.build_multinest();
            tz.plot_multinest();
        end
        function test_TZ3108_build_simul_anneal(this)
            fqfn = fullfile( ...
                "/Volumes/T7 Shield/TZ3108/sub-lou/ses-20230406/chemistry", ...
                "sub-lou_ses-20230406_pkin-recalib2.kmData.xls");
            tz = mlwong.TZ3108.create(fqfn);
            tz.build_simul_anneal();
            tz.plot_simul_anneal();
        end
        function test_KMData_create(this)
            fqfn = fullfile( ...
                "/Volumes/T7 Shield/TZ3108/sub-lou/ses-20230406/chemistry", ...
                "sub-lou_ses-20230406_pkin-recalib2.kmData.xls");
            kmd = mlpmod.KMData.create(fqfn);
            disp(kmd.header)
            disp(kmd.input_func)
            disp(kmd.regions)
            disp(kmd.scanner_data)
            disp(kmd.timesMid)
        end
    end
    
    methods (TestClassSetup)
        function setupIchise2002Model(this)
            import mlkinetics.*
            %this.testObj_ = Ichise2002Model();
        end
    end
    
    methods (TestMethodSetup)
        function setupIchise2002ModelTest(this)
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
        function T = table_mc_ptac_ro948(this, new_max)
            arguments
                this mlkinetics_unittest.Test_Ichise2002Model
                new_max double = [];
            end

            fn = fullfile(getenv("MATLABDRIVE"), "mlkinetics", "data", "RO948", ...
                "R21_004_03302023_metab_corr_ptac.csv");
            T = readtable(fn);
            Bq_mL_pTAC = 37e3*T.mc_pTAC;
            if isempty(new_max)
                return
            end
            Bq_mL_pTAC = new_max*Bq_mL_pTAC/max(Bq_mL_pTAC);
            T = addvars(T, Bq_mL_pTAC, NewVariableNames="Bq_mL_pTAC");
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
