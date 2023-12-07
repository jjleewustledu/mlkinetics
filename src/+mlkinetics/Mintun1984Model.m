classdef Mintun1984Model < handle & mlkinetics.TCModel
    %% line1
    %  line2
    %  
    %  Created 09-Sep-2023 20:34:07 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        ks_names = {'oef', 'free', 'frac. metab. H_2O', 'v_{post} + 0.5 v_{cap}'}
    end

    properties (Dependent)
    end

    methods %% GET
    end

    methods
        function this = build_model(this, opts)
            arguments
                this mlkinetics.Raichle1983Model
                opts.map containers.Map = this.preferredMap()
                opts.measurement {mustBeNumeric} = []
                opts.solver_tags = "simulanneal"
            end    

            Data = struct("raichleks",  opts.ks, "martinv1", opts.v1);
            this.map = opts.map;
            if ~isempty(opts.measurement)
                this.measurement_ = opts.measurement;
            end
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mloxygen.Mintun1984SimulAnneal(context=this, Data=Data);
            end
            if contains(opts.solver_tags, "multinest")
                this.solver_ = mloxygen.Mintun1984MultiNest(context=this, Data=Data);
            end
            if contains(opts.solver_tags, "skilling-nest")
                this.solver_ = mloxygen.Mintun1984Nest(context=this, Data=Data);
            end
        end
        function soln = build_solution(this)%% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.  

            uindex = this.unique_indices;
            Nx = numel(uindex);

            meas_ic = mlfourd.ImagingContext2(this.measurement_);
            meas_ic = this.reshape_to_parc(meas_ic);
            meas_img = double(meas_ic.imagingFormat.img);

            raichleks_ic = this.reshape_to_parc(this.raichleks_ic);
            raichleks_img = double(raichleks_ic.imagingFormat.img);

            martinv1_ic = this.reshape_to_parc(this.martinv1_ic);
            martinv1_img = double(martinv1_ic.imagingFormat.img);

            ks_mat_ = zeros([Nx, this.LENK+1]);
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve Mintun and insert solutions into ks
                this.Data = struct( ...
                    "martinv1", martinv1_img(idx), ...
                    "raichleks", raichleks_img(idx, :));
                this.build_model(measurement=asrow(meas_img(idx, :)));
                this.solver_ = this.solver_.solve(@mlkinetics.Mintun1984Model.loss_function);
                ks_mat_(idx, :) = [asrow(this.solver_.product.ks), this.solver_.loss];

                if idx < 10
                    fprintf("%s, idx->%i, uindex->%i:", stackstr(), idx, uindex(idx))
                    toc
                end

                if any(uindex(idx) == this.indicesToCheck)  
                    h = this.solver_.plot(tag="parc->"+uindex(idx));
                    saveFigure2(h, ...
                        this.fqfp + "_" + stackstr() + "_uindex" + uindex(idx), ...
                        closeFigure=true);
                end                    
            end

            ks_mat_ = single(ks_mat_);
            soln = this.product.selectImagingTool(img=ks_mat_);
            soln = this.reshape_from_parc(soln);
            soln.fqfp = this.fqfp(tag="mintunks");
            this.product_ = soln;
        end
        function [k,sk] = k1(this, varargin)
            [k,sk] = k1(this.solver_, varargin{:});
        end
        function [k,sk] = k2(this, varargin)
            [k,sk] = k2(this.solver_, varargin{:});
        end
        function [k,sk] = k3(this, varargin)
            [k,sk] = k3(this.solver_, varargin{:});
        end
        function [k,sk] = k4(this, varargin)
            [k,sk] = k4(this.solver_, varargin{:});
        end
        function [k,sk] = ks(this, varargin)
            k = zeros(1,3);
            sk = zeros(1,3);
            [k(1),sk(1)] = k1(this.solver_, varargin{:});
            [k(2),sk(2)] = k2(this.solver_, varargin{:});
            [k(3),sk(3)] = k3(this.solver_, varargin{:});
            [k(4),sk(4)] = k4(this.solver_, varargin{:});
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Mintun1984Model(varargin{:});    
            assert(~isempty(this.raichleks_ic), ...
                "%s: is missing raichleks_ic", stackstr())
            assert(~isempty(this.martinv1_ic), ...
                "%s: data_ is missing martinv1_ic", stackstr()) 

            this.LENK = 4;
        end

        function loss = loss_function(ks, Data, artery_interpolated, times_sampled, measurement, timeCliff)
            import mlkinetics.Mintun1984Model.sampled
            estimation  = sampled(ks, Data, artery_interpolated, times_sampled);
            measurement = measurement(1:length(estimation));
            positive    = measurement > 0.05*max(measurement); % & times_sampled < timeCliff;
            eoverm      = estimation(positive)./measurement(positive);
            Q           = mean(abs(1 - eoverm));
            %Q           = mean((1 - eoverm).^2);
            loss        = Q; % 0.5*Q/sigma0^2 + sum(log(sigma0*measurement)); % sigma ~ sigma0*measurement
        end
        function m = preferredMap()
            %% init from Mintun J Nucl Med 25:177-187, 198.
            %  metabf described in Fig. 7.
            
            m = containers.Map;
            m('k1') = struct('min', 0.14, 'max', 0.74, 'init', 0.44,  'sigma', 0.01); % oef +/- 5 std
            m('k2') = struct('min', 0,    'max', 1.0,  'init', 0.5,   'sigma', 0.01); % unused, control for fluctuations of simulanneal
            m('k3') = struct('min', 0.2,  'max', 0.8,  'init', 0.5,   'sigma', 0.1); % activity(HO)/(activity(HO) + activity(OO)) at 90 sec
            m('k4') = struct('min', 0.5,  'max', 1,    'init', 0.835, 'sigma', 0.1); % v_post + 0.5 v_cap
        end
        function qs = sampled(ks, Data, artery_interpolated, times_sampled)
            %  @param artery_interpolated is uniformly sampled at high sampling freq.
            %  @param times_sampled are samples scheduled by the time-resolved PET reconstruction
            
            qs = mlkinetics.Mintun1984Model.solution(ks, Data, artery_interpolated);
            qs = mlkinetics.Mintun1984Model.solutionOnScannerFrames(qs, times_sampled);
        end
        function rho = solution(ks, Data, artery_interpolated)
            %  @param artery_interpolated is uniform with high sampling freq. starting at time = 0.

            import mlkinetics.OxyMetabConversion

            HALFLIFE = 122.2416;
            ALPHA = 0.005670305; % log(2)/halflife in 1/s
            
            %ad = mlaif.AifData.instance();
            %tBuffer = ad.tBuffer;
            tBuffer = 0;
            [~,idx0] = max(artery_interpolated > 0.05*max(artery_interpolated));
            idxU = idx0 + 90; % cf. Mintun1984
            
            oef = ks(1);
            %metabTail = ks(2); 
            metabFrac = ks(3); 
            v_post_cap = ks(4);
            f = Data.raichleks(1);
            lambda = Data.raichleks(2); 
            PS = Data.raichleks(3);
            Delta = Data.raichleks(4);
            v1 = Data.martinv1;
            m = 1 - exp(-PS/f);
            n = length(artery_interpolated);
            times = 0:1:n-1;
            timesb = times; % - tBuffer;             
            % use Delta
            if Delta > 0.01
                auc0 = trapz(artery_interpolated);
                artery_interpolated1 = conv(artery_interpolated, exp(-Delta*times));
                artery_interpolated1 = artery_interpolated1(1:n);
                artery_interpolated1 = artery_interpolated1*auc0/trapz(artery_interpolated1);
            else
                artery_interpolated1 = artery_interpolated;
            end

            %% estimate shape of water of metabolism
            shape = zeros(1, n);
            n1 = n - idx0 + 1;
            y = (n - idx0)/(idxU - idx0);
            shape(end-n1+1:end) = linspace(0, y, n1); % shape(idxU) == 1
            ductimes = zeros(1,n);
            ductimes(idx0:end) = 0:(n1-1);
            ducshape = shape .* 2.^(-(ductimes - idxU + 1)/HALFLIFE); % decay-uncorrected
            
            %% set scale of artery_h2o
            metabScale = metabFrac*artery_interpolated1(idxU); % activity water of metab \approx activity of oxygen after 90 sec
            metabScale = metabScale*OxyMetabConversion.DENSITY_PLASMA/OxyMetabConversion.DENSITY_BLOOD;
            artery_h2o = metabScale*ducshape;                     
            
            %% compartment 2, using m, f, lambda
            artery_o2 = artery_interpolated1 - artery_h2o;
            artery_o2(artery_o2 < 0) = 0;   
            kernel = exp(-m*f*timesb/lambda - ALPHA*timesb);
            rho2 =  m*f*conv(kernel, artery_h2o) + ...
                oef*m*f*conv(kernel, artery_o2);
            
            %% compartment 1
            % v_post = 0.83*v1;
            % v_cap = 0.01*v1;
            R = 0.85; % ratio of small-vessel to large-vessel Hct
            rho1 = v1*R*(1 - oef*v_post_cap)*artery_o2;
            
            rho = rho1(1:n) + rho2(1:n);        
            rho = rho(tBuffer+1:n);
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
    end

    %% PRIVATE

    methods (Access=private)
        function this = Mintun1984Model(varargin)
            this = this@mlkinetics.TCModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
