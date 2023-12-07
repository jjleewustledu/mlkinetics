classdef (Sealed) Huang1980Model < handle & mlkinetics.TCModel
    %% line1
    %  line2
    % 
    %  Expectations:
    %      glc double = 100
    %      hct double = 0.4375
    %      LC double = 0.81    
    %  
    %  Created 13-Jun-2023 22:30:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
        
    properties (Constant)
        ks_names = {'k_1', 'k_2', 'k_3', 'k_4', '\Delta'}
        LC = 0.81
    end

    properties (Dependent)
    end

    methods %% GET
    end

    methods
        function this = build_model(this, opts)
            arguments
                this mlkinetics.Huang1980Model
                opts.map containers.Map = this.preferredMap()
                opts.measurement {mustBeNumeric} = []
                opts.solver_tags = "simulanneal"
            end
            this.map = opts.map;  
            if ~isempty(opts.measurement)
                this.measurement_ = opts.measurement;
            end          
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mlglucose.Huang1980SimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinest")
                this.solver_ = mlglucose.Huang1980MultiNest(context=this);
            end
            if contains(opts.solver_tags, "skilling-nest")
                this.solver_ = mlglucose.Huang1980Nest(context=this);
            end
        end
        function soln = build_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.                                

            uindex = this.unique_indices;
            Nx = numel(uindex);

            meas_ic = mlfourd.ImagingContext2(this.measurement_);
            meas_ic = this.reshape_to_parc(meas_ic);
            meas_img = meas_ic.imagingFormat.img;

            martinv1_ic = this.reshape_to_parc(this.martinv1_ic);
            martinv1_img = double(martinv1_ic.imagingFormat.img);

            radm = this.tracer_kit_.make_handleto_counter();
            glc = this.glcFromRadMeasurements(radm);

            ks_mat_ = zeros([Nx this.LENK+1], 'single');
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve Huang and insert solutions into ks
                this.Data = struct( ...
                    "martinv1", martinv1_img(idx), ...
                    "glc", glc);
                this.build_model(measurement = asrow(meas_img(idx, :)));
                this.solver_ = this.solver_.solve(@mlkinetics.Huang1980Model.loss_function);
                ks_mat_(idx, :) = [asrow(this.solver_.product.ks), this.solver_.loss];

                if idx < 10
                    fprintf("%s, idx->%i, uindex->%i:", stackstr(), idx, uindex(idx))
                    toc
                end

                if any(uindex(idx) == this.indicesToCheck)
                    h = this.solver_.plot(tag="parc->"+uindex(idx));
                    saveFigure2(h, ...
                        this.product.fqfp + "_" + stackstr() + "_uindex" + uindex(idx), ...
                        closeFigure=true);
                end
            end

            ks_mat_ = single(ks_mat_);
            soln = this.product.selectImagingTool(img=ks_mat_);
            soln = this.reshape_from_parc(soln);
            soln.fqfp = this.fqfp(tag="huangks");
            this.product_ = soln;            
        end
        function r = cmrglc(this, varargin)
            %  @return umol/hg/min
            
            % [umol/mmol] [(mmol/L) / (mg/dL)] [L/dL] [dL/mL] [g/hg] [mL/g] == [umol/hg]
            glc_ = this.trcMassConversion(this.Data.glc, 'mg/dL', 'umol/hg'); 
            r = 60*this.chi(varargin{:})*glc_;
        end
        function c = chi(this, varargin)
            %  @return 1/s
            
            c = K1(this, varargin{:}).*k3(this, varargin{:})./ ...
                (k2(this, varargin{:}) + k3(this, varargin{:}));
            c = c/this.LC;
        end
        function [K,sK] = K1(this, varargin)
            [k,sk] = k1(this.solver_, varargin{:});
            v1 = this.Data.martinv1;
            K = v1*k;
            sK = v1*sk;
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
        function [k,sk] = k5(this, varargin)
            [k,sk] = k5(this.strategy_, varargin{:});
        end
        function [K,sK] = Ks(this, varargin)
            K = zeros(1,5);
            sK = zeros(1,5);
            [K(1),sK(1)] = K1(this.solver_, varargin{:});
            [K(2),sK(2)] = k2(this.solver_, varargin{:});
            [K(3),sK(3)] = k3(this.solver_, varargin{:});
            [K(4),sK(4)] = k4(this.solver_, varargin{:});
            [K(5),sK(5)] = k5(this.solver_, varargin{:});
        end
        function [k,sk] = ks(this, varargin)
            k = zeros(1,5);
            sk = zeros(1,5);
            [k(1),sk(1)] = k1(this.solver_, varargin{:});
            [k(2),sk(2)] = k2(this.solver_, varargin{:});
            [k(3),sk(3)] = k3(this.solver_, varargin{:});
            [k(4),sk(4)] = k4(this.solver_, varargin{:});
            [k(5),sk(5)] = k5(this.solver_, varargin{:});
        end

        %% UTILITIES

        function p = wb2plasma(this, wb, opts)
            arguments
                this mlkinetics.Huang1980Model
                wb {mustBeNumeric}
                opts.wb_times {mustBeNumeric} = []
            end
            if isempty(opts.wb_times)
                opts.wb_times = 0:length(wb)-1;
            end

            radm = this.tracer_kit_.make_handleto_counter();
            hct = this.hctFromRadMeasurements(radm);
            p = mlraichle.RBCPartition.wb2plasma(wb, hct, opts.wb_times, "s");
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Huang1980Model(varargin{:});
            assert(~isempty(this.martinv1_ic), ...
                "%s: data_ is missing martinv1_ic", stackstr())

            this.LENK = 5;
        end

        %% builder methods for model

        function g = glcFromRadMeasurements(radm)
            %  @return mg/dL
            
            tbl = radm.laboratory;
            rows = tbl.Properties.RowNames;
            select = contains(rows, 'glc');
            g = tbl.measurement(select);
            g = mean(g(find(g)), 'omitnan'); %#ok<FNDSB>
        end
        function h = hctFromRadMeasurements(radm)
            h = radm.laboratory{'Hct', 'measurement'};
            if h > 1
                h = h/100;
            end
        end
        function loss = loss_function(ks, Data, artery_interpolated, times_sampled, measurement, timeCliff)
            import mlkinetics.Huang1980Model.sampled            
            estimation  = sampled(ks, Data, artery_interpolated, times_sampled);
            measurement = measurement(1:length(estimation));
            positive    = measurement > 0.05*max(measurement); % & times_sampled < timeCliff;
            eoverm      = estimation(positive)./measurement(positive);            
            Q           = mean(abs(1 - eoverm));
            %Q           = sum((1 - eoverm).^2);
            loss        = Q; % 0.5*Q/sigma0^2 + sum(log(sigma0*measurement)); % sigma ~ sigma0*measurement
        end
        function m    = preferredMap()
            %% init from Huang's table 1
            m = containers.Map;
            m('k1') = struct('min', eps,  'max',  0.5,   'init', 0.048,   'sigma', 0.0048);
            m('k2') = struct('min', eps,  'max',  0.02,  'init', 0.0022,  'sigma', 0.0022);
            m('k3') = struct('min', eps,  'max',  0.01,  'init', 0.001,   'sigma', 0.0001);
            m('k4') = struct('min', eps,  'max',  0.001, 'init', 0.00011, 'sigma', 0.00011);
            m('k5') = struct('min', 0.02, 'max',  1,     'init', 0.1,     'sigma', 0.05); % Delta for arterial dispersion
        end
        function qs   = sampled(ks, Data, artery_interpolated, times_sampled)
            %  @param artery_interpolated is uniformly sampled at high sampling freq.
            %  @param times_sampled are samples scheduled by the time-resolved PET reconstruction
            
            qs = mlkinetics.Huang1980Model.solution(ks, Data, artery_interpolated);
            qs = mlkinetics.Huang1980Model.solutionOnScannerFrames(qs, times_sampled);
        end
        function qs   = solution(ks, Data, artery_interpolated)
            %  @param artery_interpolated is uniformly sampled at high sampling freq. starting at time = 0.

            tBuffer = 0;
            
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            Delta = ks(5);
            v1 = Data.martinv1;
            scale = 1;            
            n = length(artery_interpolated);
            times = 0:1:n-1;
            timesb = times; % - tBuffer;
            
            % use Delta
            auc0 = trapz(artery_interpolated);
            artery_interpolated1 = conv(artery_interpolated, exp(-Delta*times));
            artery_interpolated1 = artery_interpolated1(1:n);
            artery_interpolated1 = artery_interpolated1*auc0/trapz(artery_interpolated1);
            
            % use k1:k4
            k234 = k2 + k3 + k4;         
            bminusa = sqrt(k234^2 - 4 * k2 * k4);
            alpha = 0.5 * (k234 - bminusa);
            beta  = 0.5 * (k234 + bminusa);   
            conva = conv(exp(-alpha .* timesb), artery_interpolated1);
            convb = conv(exp(-beta .* timesb), artery_interpolated1);
            conva = conva(1:n);
            convb = convb(1:n);
            conv2 = (k4 - alpha) .* conva + (beta - k4) .* convb;
            conv3 =                 conva -                convb;
            q2 = (k1 / bminusa)      * conv2;
            q3 = (k3 * k1 / bminusa) * conv3;
            qs = v1 * (artery_interpolated1 + scale*(q2 + q3)); 
            qs = qs(tBuffer+1:n);
        end 

        %% UTILITIES

        function g = trcMassConversion(g, unitsIn, unitsOut)
            %  @param required g is numeric
            %  @param required unitsIn, unitsOut in {'mg/dL' 'mmol/L' 'umol/hg'}
            
            assert(isnumeric(g))
            assert(ischar(unitsIn))
            assert(ischar(unitsOut))
            if strcmp(unitsIn, unitsOut)
                return
            end
            
            switch unitsIn % to SI
                case 'mg/dL'
                    g = g * this.mgdL_to_mmolL;
                case 'mmol/L'
                case 'umol/hg'
                    % [mmol/L] == [umol/hg] [mmol/umol] [hg/g] [g/mL] [mL/L] 
                    g = g * 1e-3 * 1e-2 * 1.05 * 1e3;
                otherwise
                    error('mlglucose:ValueError', 'Huang1980.gclConversion')
            end
            
            switch unitsOut % SI to desired
                case 'mg/dL'
                    g = g / this.mgdL_to_mmolL;
                case 'mmol/L'
                case 'umol/hg'
                    % [umol/hg] == [mmol/L] [umol/mmol] [L/mL] [mL/g] [g/hg] 
                    g = g * 1e3 * 1e-3 * (1/1.05) * 1e2;
                otherwise
                    error('mlglucose:ValueError', 'Huang1980.gclConversion')
            end
        end
    end
    
    %% PRIVATE

    methods (Access = private)
        function this = Huang1980Model(varargin)
            this = this@mlkinetics.TCModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
