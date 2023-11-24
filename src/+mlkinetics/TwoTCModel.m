classdef (Sealed) TwoTCModel < handle & mlkinetics.TCModel
    %% line1
    %  line2
    %  
    %  Created 06-Oct-2023 14:30:29 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function this = build_model(this, opts)
            arguments
                this mlkinetics.TwoTCModel
                opts.solver_tags = "simulanneal"
                opts.content double = nan
                opts.map containers.Map = this.preferredMap()
                opts.times_sampled double = []
                opts.artery_interpolated double = []
            end

            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mlkinetics.TwoTCSimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinext")
                this.solver_ = mlkinetics.TwoTCMultiNest(context=this);
            end
        end
        function c = chi(this, varargin)
            %  @return 1/s
            
            c = K1(this, varargin{:}).*k3(this, varargin{:})./ ...
                (k2(this, varargin{:}) + k3(this, varargin{:}));
        end
        function [K,sK] = K1(this, varargin)
            [K,sK] = K1(this.solver_, varargin{:});
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
        function [K,sK] = Ks(this, varargin)
            K = zeros(1,4);
            sK = zeros(1,4);
            [K(1),sK(1)] = K1(this.solver_, varargin{:});
            [K(2),sK(2)] = k2(this.solver_, varargin{:});
            [K(3),sK(3)] = k3(this.solver_, varargin{:});
            [K(4),sK(4)] = k4(this.solver_, varargin{:});
        end
        function soln = make_solution(this)
        end        
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.TwoTCModel(varargin{:});
            this.LENK = 5;
            this.mgdL_to_mmolL = nan;
            [this.measurement_,this.times_sampled_,this.t0_,this.artery_interpolated_] = this.mixTacAif();

            % apply kinetics assumptions
            this = build_model(this);
        end

        %% builder methods for model

        function loss = loss_function(ks, v1, artery_interpolated, times_sampled, measurement, ~)
            import mlglucose.DispersedHuang1980Model.sampled            
            estimation  = sampled(ks, v1, artery_interpolated, times_sampled);
            measurement = measurement(1:length(estimation));
            positive    = measurement > 0.05*max(measurement);
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
        function qs   = sampled(ks, v1, artery_interpolated, times_sampled)
            %  @param artery_interpolated is uniformly sampled at high sampling freq.
            %  @param times_sampled are samples scheduled by the time-resolved PET reconstruction
            
            import mlglucose.DispersedHuang1980Model.solution 
            import mlpet.TracerKineticsModel.solutionOnScannerFrames  
            qs = solution(ks, v1, artery_interpolated);
            qs = solutionOnScannerFrames(qs, times_sampled);
        end
        function qs   = solution(ks, v1, artery_interpolated)
            %  @param artery_interpolated is uniformly sampled at high sampling freq. starting at time = 0.

            ad = mlaif.AifData.instance();
            tBuffer = ad.tBuffer;
            
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            Delta = ks(5);
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
            qs = v1 * (artery_interpolated1 + scale * (q2 + q3)); 
            qs = qs(tBuffer+1:n);
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = TwoTCModel(varargin)
            this = this@mlkinetics.TCModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
