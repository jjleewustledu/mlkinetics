classdef QuadraticMintun1984Model < handle & mlkinetics.QuadraticModel
    %% QUADRATICMINTUN1984MODEL
    %  N.B. assumptions made in build_metabolites(this, ).
    %  
    %  Created 06-Sep-2023 15:20:40 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        oo_ic

        artery_oxygen
        artery_water_metab
        cbf_ic
        cbv_ic
        integral_artery_oxygen
    end

    methods %% GET
        function g = get.oo_ic(this)
            if ~isempty(this.oo_ic_)
                g = copy(this.oo_ic_);
                return
            end
            this.oo_ic_ = this.scanner_kit_.do_make_activity_density();
            g = copy(this.oo_ic_);
        end

        function g = get.artery_oxygen(this)
            g = this.artery_oxygen_;
            assert(~isempty(g));
        end
        function g = get.artery_water_metab(this)
            g = this.artery_water_metab_;
            assert(~isempty(g));
        end
        function g = get.cbf_ic(this)
            g = this.cbf_ic_;
            assert(~isempty(g));            
        end
        function g = get.cbv_ic(this)
            g = this.cbv_ic_;
            assert(~isempty(g));            
        end
        function g = get.integral_artery_oxygen(this)
            g = this.integral_artery_oxygen_;
            assert(~isempty(g));
        end
    end

    methods
        function this = build_metabolites(this)
            import mlkinetics.OxyMetabConversion

            [~,idx0] = max(this.artery_interpolated_ > 0.05*max(this.artery_interpolated_));
            idxU = idx0 + 90;
            metabFrac = 0.5; % activity(HO)/(activity(HO) + activity(OO)) at 90 sec
            n = length(this.artery_interpolated_);
            
            %% estimate shape of water of metabolism
            shape = zeros(1, n);
            n1 = n - idx0 + 1;
            y = (n - idx0)/(idxU - idx0);
            shape(end-n1+1:end) = linspace(0, y, n1); % shape(idxU) == 1
            ductimes = zeros(1,n);
            ductimes(idx0:end) = 0:(n1-1);
            ducshape = shape .* 2.^(-(ductimes - idxU + 1)/122.2416); % decay-uncorrected
            
            %% set scale of artery_h2o
            metabScale = metabFrac*this.artery_interpolated_(idxU); % activity water of metab \approx activity of oxygen after 90 sec
            metabScale = metabScale*OxyMetabConversion.DENSITY_PLASMA/OxyMetabConversion.DENSITY_BLOOD;
            
            %% set internal params
            this.artery_water_metab_ = metabScale*ducshape;     
            select = this.artery_water_metab_ > this.artery_interpolated_;
            this.artery_water_metab_(select) = this.artery_interpolated_(select);
            this.artery_oxygen_ = this.artery_interpolated_ - this.artery_water_metab_;
            this.integral_artery_oxygen_ = ...
                0.01*OxyMetabConversion.RATIO_SMALL_LARGE_HCT*OxyMetabConversion.DENSITY_BRAIN* ...
                trapz(this.artery_oxygen_(this.t0+1:this.tF+1));
        end
        function mdl = build_model(~, obs, f1)
            %% build_model 
            %  @param obs are numeric PET_{obs} := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param f1 are numeric F1 or similar flows in 1/s.
            %  @returns mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('QuadraticMintun1984Model.build_model ..........\n');
            mdl = fitnlm( ...
                ascolumn(f1), ...
                ascolumn(obs), ...
                @mlkinetics.QuadraticModel.obsPetQuadraticModel, ...
                [1 1]);
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(obs), max(obs));
            if ~isempty(getenv('DEBUG'))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
        end
        function soln = build_solution(this)

            % check dynamic imaging

            % check & adjust input functions, esp. their timings and timing boundaries, 
            % to match dynamic imaging 

            % preliminaries:  fileprefix, point-spread, existing cbf & cbv
            med = this.bids_kit_.make_bids_med();
            prefix = sprintf("%s_%s", med.subjectFolder, med.sessionFolder);
            ps = med.petPointSpread();
            cbf_ic__ = this.cbf_ic.blurred(ps); % pre-blur polynomial
            f_ic__ = mlkinetics.OxyMetabConversion.cbfToF1(cbf_ic__);
            cbv_ic__ = this.cbv_ic.blurred(ps); % pre-blur polynomial; integral_artery_oxygen converts cbv -> v1

            % quadratic models
            obsWaterMetab = this.obsFromAif(this.artery_water_metab, this.canonical_f); % time series -> \int_t rho(t), in sec
            this.modelB12 = this.build_model(obsWaterMetab, this.canonical_f); % N.B. nonlin model mapping f -> obs            
            
            obsOxygen = this.obsFromAif(this.artery_oxygen, this.canonical_f); % time series -> \int_t rho(t), in sec
            this.modelB34 = this.build_model(obsOxygen, this.canonical_f); % N.B. nonlin model mapping f -> obs
            
            poly12_ic = f_ic__.^2.*this.b1 + f_ic__.*this.b2;
            poly34_ic = f_ic__.^2.*this.b3 + f_ic__.*this.b4;

            % PET_{obs}
            obsPet_ifc = copy(this.dlicv_ic.imagingFormat);
            obsPet_ifc.img = this.obsFromTac(this.measurement_, t0=this.t0, tF=this.tF);
            obsPet_ic = mlfourd.ImagingContext2(obsPet_ifc);
            obsPet_ic = obsPet_ic.blurred(ps);

            % oef by quadratic models
            numerator_ic = obsPet_ic - poly12_ic - cbv_ic__*this.integral_artery_oxygen; % N.B. confusion of a1,a2,a3,a4 by Herscovitch 1985
            numerator_ic.fileprefix = sprintf("%s_%s_numerator_ic", prefix, stackstr());
            numerator_ic.filepath = this.oo_ic.filepath;
            numerator_ic.save();
            denominator_ic = poly34_ic - cbv_ic__*0.835*this.integral_artery_oxygen;
            denominator_ic.fileprefix = sprintf("%s_%s_denominator_ic", prefix, stackstr());
            denominator_ic.filepath = this.oo_ic.filepath;
            denominator_ic.save();

            ratio_ic = numerator_ic ./ denominator_ic;            
            ratio_ic = ratio_ic .* this.dlicv_ic;
            ratio_ic = ratio_ic.scrubNanInf();
            %ratio_ic = ratio_ic.thresh(0);
            %ratio_ic = ratio_ic.uthresh(1);
            img = ratio_ic.imagingFormat.img;
            img(img < 0) = 0;
            img(img > 1) = 1;
            
            soln = copy(this.oo_ic.imagingFormat);
            soln.img = single(img);
            soln.fileprefix = strrep(this.oo_ic.fileprefix, "_trc-oo", "_oef");
            soln = mlfourd.ImagingContext2(soln);
            this.product_ = soln; % fullfills mlkinetics.Model's builder design pattern for oef

            % plot arterial time series
            h = plot(0:344, this.artery_water_metab, 0:344, this.artery_oxygen);
            xlabel("time (s)"); 
            ylabel("activity density (Bq/mL)");
            legend(["arterial water of metab", "arterial oxygen"])
            saveFigure2(h, prefix+stackstr()+"_Mintun_arterial_times_series")
        end

        %% UTILITIES

        function [crc,output] = cbv_recovery_coeff(this, cbv_ic__, obsPet_ic, poly12_ic, poly34_ic)
            %% https://www.mathworks.com/help/matlab/math/optimizing-nonlinear-functions.html

            import mlkinetics.QuadraticMintun1984Model.crc_objective

            % assemble int_art_O2
            icv = logical(this.dlicv_ic.imagingFormat.img);
            vec_int_artO2_ = cbv_ic__.imagingFormat.img(icv)*this.integral_artery_oxygen;
            int_art_O2 = double([vec_int_artO2_; vec_int_artO2_*0.835]);

            % assemble obs_pet
            vec_numer_ = obsPet_ic - poly12_ic;
            vec_numer_ = vec_numer_.imagingFormat.img(icv);
            vec_denom_ = poly34_ic.imagingFormat.img(icv);
            obs_pet = double([vec_numer_; vec_denom_]);

            % find min_{crc} abs(obs_pet - int_art_O2*crc)
            options = optimset(Display='iter');
            [crc,~,exitflag,output] = fminbnd(@(crc__) crc_objective(obs_pet, int_art_O2, crc__), 0.01, 100, options);
            if ~(exitflag == 1)
                warning("mlkinetics:RunTimeWarning", "%s: exitflag->%g", stackstr(), exitflag)
            end
        end
        function t = tauObs(~)
            t = 40;
        end
        function t = timeStar(~)
            t = 0; 
        end
    end
    
    methods (Static)
        function this = create(varargin)

            this = mlkinetics.QuadraticMintun1984Model(varargin{:});

            assert(isfield(this.data, "cbf_ic"), ...
                "%s: data is missing cbf_ic", stackstr())
            assert(isfield(this.data, "cbv_ic"), ...
                "%s: data is missing cbv_ic", stackstr())
            this.cbf_ic_ = this.data.cbf_ic;
            this.cbv_ic_ = this.data.cbv_ic;

            % apply Mintun's kinetics assumptions
            this = build_metabolites(this);
        end
    end

    %% PRIVATE

    properties (Access=private)
        oo_ic_

        artery_oxygen_
        artery_water_metab_
        cbf_ic_
        cbv_ic_
        integral_artery_oxygen_
    end

    methods (Access=private)
        function this = QuadraticMintun1984Model(varargin)
            this = this@mlkinetics.QuadraticModel(varargin{:});
        end
    end

    methods (Static, Access=private)
        function obj = crc_objective(obs_pet, int_art_O2, crc)
            obj = min(obs_pet - int_art_O2*crc);
            if obj < 0
                obj = -obj;
            end
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
