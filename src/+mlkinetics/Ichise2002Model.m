classdef Ichise2002Model < handle & mlkinetics.Model
    %% is a concrete factory from a design pattern providing an interface for Ichise multilinear analysis 
    %  (Ichise 2002).
    %  It is a singleton (cf. GoF pg. 90).
    %  It provides interfaces for varieties of radiotracer data, models, and analysis choices.
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/),
    %  tracers, scanners, input function methods, kinetic models, inference methods, and parcellations.  
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.ScannerKit, 
    %  mlkinetics.TracerKit, mlkinetics.ModelKit, mlkinetics.InferenceKit, mlkinetics.InputFunctionKit, 
    %  mlkinetics.ParcellationKit.
    % 
    %  Created 26-Apr-2023 19:19:49 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        ks_names = {'K_1', 'k_2', 'k_3', 'k_4', 'V_P', 'V_N + V_S'}
    end
    
    properties
        LENK
        map
    end

    properties (Dependent)
        solver
    end

    methods %% GET, SET
        function g = get.solver(this)
            g = this.solver_;
        end
        function set.solver(this, s)
            this.solver_ = s;
        end
    end

    methods
        function this = build_model(this, opts)
            arguments
                this mlkinetics.Ichise2002Model
                opts.map containers.Map = this.preferredMap()
                opts.measurement {mustBeNumeric} = []
                opts.solver_tags = "simulanneal"
            end
            this.map = opts.map;  
            if ~isempty(opts.measurement)
                this.measurement_ = opts.measurement;
            end          
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mlpet.Ichise2002SimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinest")
                this.solver_ = mlpet.Ichise2002MultiNest(context=this);
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

            ks_mat_ = zeros([Nx this.LENK+1], 'single');
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve Ichise and insert solutions into ks
                measurement_ = asrow(meas_img(idx, :));
                this.Data = struct( ...
                    'measurement_sampled', measurement_, ...
                    'times_sampled', this.times_sampled);
                this.build_model(measurement=measurement_);
                this.solver_ = this.solver_.solve(@mlpet.Ichise2002Model.loss_function);
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
            soln.fileprefix = strrep(this.product.fileprefix, "_pet", "_ichiseks");
            this.product_ = soln;     
        end

        function [k,sK] = K1(this, varargin)
            [k,sK] = k1(this.solver_, varargin{:});
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
        function [ks,sks] = ks(this, varargin)
            ks = zeros(1,6);
            sks = zeros(1,6);
            [ks(1),sks(1)] = k1(this.solver_, varargin{:});
            [ks(2),sks(2)] = k2(this.solver_, varargin{:});
            [ks(3),sks(3)] = k3(this.solver_, varargin{:});
            [ks(4),sks(4)] = k4(this.solver_, varargin{:});
            [ks(5),sks(5)] = k5(this.solver_, varargin{:});
            [ks(6),sks(6)] = k6(this.solver_, varargin{:});
        end
        function [V,sV] = VT(this, varargin)
            [V,sV] = Vstar(this, varargin{:});
        end
        function [V,sV] = VN(this, varargin)
            ks = this.ks(varargin{:});
            VN_plus_VS = ks(6);
            V = VN_plus_VS - this.VS(varargin{:});

            sV = NaN;
        end
        function [V,sV] = VS(this, varargin)
            ks = this.ks(varargin{:});
            K1 = ks(1);
            VP = ks(5);
            Vstar = sum(ks(5:6));
            g1 = ks(2)*ks(4)*Vstar;
            g2 = -ks(2)*ks(4);
            g3 = -sum(ks(2:4));
            g4star = K1;
            g5 = VP;
            
            numer = g1*(g1 + g3*g4star) + g2*(g4star + g3*g5)^2;
            logV = log(numer) - log(g2) - log((g1 + g3*g4star));
            V = real(exp(logV));

            sV = NaN;
        end
        function [V,sV] = VP(this, varargin)
            ks = this.ks(varargin{:});
            V = ks(5);

            sV = NaN;
        end
        function [V,sV] = Vstar(this, varargin)
            ks = this.ks(varargin{:});
            V = sum(ks(5:6));

            sV = NaN;
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Ichise2002Model(varargin{:});

            this.LENK = 5;
        end

        function loss = loss_function(ks, Data, plasma_interpolated, times_sampled, measurement, timeCliff)
            import mlkinetics.Ichise2002Model.sampled
            estimation  = sampled(ks, Data, plasma_interpolated, times_sampled);
            measurement = measurement(1:length(estimation));
            measurement = measurement/max(measurement);
            positive    = measurement > 0.05; % & times_sampled < timeCliff;
            eoverm      = estimation(positive)./measurement(positive);            
            Q           = mean(abs(1 - eoverm));
            %Q           = sum((1 - eoverm).^2);
            loss        = Q; % 0.5*Q/sigma0^2 + sum(log(sigma0*measurement)); % sigma ~ sigma0*measurement
        end
        function m    = preferredMap(opts)
            arguments
                opts.tracer {mustBeTextScalar} = ""
            end

            if contains(opts.tracer, "mdl", IgnoreCase=true)
                m = mlkinetics.Ichise2002Model.preferredMap_mdl();
                return
            end
            if contains(opts.tracer, "fdg", IgnoreCase=true)
                m = mlkinetics.Ichise2002Model.preferredMap_fdg();
                return
            end
            m = mlkinetics.Ichise2002Model.preferredMap_unknown();
        end
        function m    = preferredMap_fdg()
            %% k1 ~ K1, k5 ~ VP, k6 ~ VN + VS;
            %  tuned for FDG.
            
            m = containers.Map;
            m('k1') = struct('min', eps,   'max',    0.5,   'init', 0.048,   'sigma', 0.048);
            m('k2') = struct('min', eps,   'max',    0.02,  'init', 0.0022,  'sigma', 0.0022);
            m('k3') = struct('min', eps,   'max',    0.01,  'init', 0.001,   'sigma', 0.001);
            m('k4') = struct('min', eps,   'max',    0.001, 'init', 0.00011, 'sigma', 0.00011);
            m('k5') = struct('min',   0.1, 'max',   10,     'init', 1,       'sigma', 0.05); % VP
            m('k6') = struct('min',   1,   'max',  100,     'init', 1,       'sigma', 0.05); % VN + VS
        end
        function m    = preferredMap_mdl()
            %% k1 ~ K1, k5 ~ VP, k6 ~ VN + VS
 
            m = containers.Map;
            m('k1') = struct('min', 1e-4, 'max',    9/60,   'init', 0.8542/60, 'sigma', 0.048);
            m('k2') = struct('min', 1e-4, 'max',    0.8/60, 'init', 0.0785/60, 'sigma', 0.0022);
            m('k3') = struct('min', 1e-4, 'max',    0.5/60, 'init', 0.0502/60, 'sigma', 0.001);
            m('k4') = struct('min', 1e-4, 'max',    0.2/60, 'init', 0.0227/60, 'sigma', 0.00011);
            m('k5') = struct('min', 0.1,  'max',   10,      'init', 1,         'sigma', 0.05); % VP
            m('k6') = struct('min', 1,    'max',  100,      'init', 1,         'sigma', 0.05); % VN + VS
        end
        function m    = preferredMap_unknown()
            %% k1 ~ K1, k5 ~ VP, k6 ~ VN + VS;
            %  tuned for FDG.
            
            m = containers.Map;
            m('k1') = struct('min', eps,   'max',    0.5,   'init', 0.048,   'sigma', 0.048);
            m('k2') = struct('min', eps,   'max',    0.02,  'init', 0.0022,  'sigma', 0.0022);
            m('k3') = struct('min', eps,   'max',    0.01,  'init', 0.001,   'sigma', 0.001);
            m('k4') = struct('min', eps,   'max',    0.001, 'init', 0.00011, 'sigma', 0.00011);
            m('k5') = struct('min',   0.1, 'max',   10,     'init', 1,       'sigma', 0.05); % VP
            m('k6') = struct('min',   1,   'max',  100,     'init', 1,       'sigma', 0.05); % VN + VS
        end
        function C_T   = sampled(ks, Data, plasma_interpolated, times_sampled)
            %  @param artery_interpolated is uniformly sampled at high sampling freq.
            %  @param times_sampled are samples scheduled by the time-resolved PET reconstruction
            
            Data.times_sampled = times_sampled;
            C_T = mlkinetics.Ichise2002Model.solution(ks, Data, plasma_interpolated);
            %C_T = mlkinetics.Ichise2002Model.solutionOnScannerFrames(qs, times_sampled);
        end
        function C_T  = solution(ks, Data, plasma_interpolated)
            %% k1 ~ K1, k5 ~ VP, regional plasma volume-of-distrib., k6 ~ VN + VS

            meas_samp = Data.measurement_sampled;
            times_samp = Data.times_sampled;
            times = Data.times;
            Nt = length(plasma_interpolated);

            K1 = ks(1);
            VP = ks(5);
            Vstar = sum(ks(5:6));
            g1 = ks(2)*ks(4)*Vstar;
            g2 = -ks(2)*ks(4);
            g3 = -(sum(ks(2:4)));
            g4star = K1;
            g5 = VP;

            C_T = zeros(size(times_samp));
            for tidx = 2:length(times_samp)
                m_ = meas_samp(1:tidx);
                t_ = times_samp(1:tidx);
                times_ = 0:min(times(tidx), Nt - 1);
                p_ = plasma_interpolated(times_+1); 
                
                int3 = trapz(t_, m_); 
                int4 = trapz(times_, p_);
                int2 = 0.5*trapz(t_, cumtrapz(t_, m_));
                int1 = 0.5*trapz(times_, cumtrapz(times_, p_));

                C_T(tidx) = g1*int1 + g2*int2 + g3*int3 + g4star*int4 + ...
                    g5*plasma_interpolated(times_samp(tidx)+1);
            end
            C_T = C_T/max(C_T);
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = Ichise2002Model(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
