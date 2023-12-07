classdef (Sealed) TwoTCModel < handle & mlkinetics.TCModel
    %% line1
    %  line2
    %  
    %  Created 06-Oct-2023 14:30:29 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        ks_names = {'K_1', 'k_2', 'k_3', 'k_4', '\Delta'}
    end

    methods
        function this = build_model(this, opts)
            arguments
                this mlkinetics.TwoTCModel
                opts.map containers.Map = this.preferredMap()
                opts.measurement {mustBeNumeric} = []
                opts.solver_tags = "simulanneal"
            end

            this.map = opts.map;  
            if ~isempty(opts.measurement)
                this.measurement_ = opts.measurement;
            end
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mlkinetics.TwoTCSimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinest")
                this.solver_ = mlkinetics.TwoTCMultiNest(context=this);
            end
            if contains(opts.solver_tags, "skilling-nest")
                this.solver_ = mlkinetics.HTwoTCNest(context=this);
            end
        end
        function soln = build_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.                                

            uindex = this.unique_indices;
            Nx = size(this.parc, 1); % unique indices
            % compare to Ny = size(this.parc, 2); % corresponding to timesMid

            meas_ic = mlfourd.ImagingContext2(this.measurement_);
            meas_ic = this.parc_kit_.make_parc(meas_ic);
            meas_img = meas_ic.imagingFormat.img;

            ks_mat_ = zeros([Nx this.LENK+1], 'single');
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve Huang and insert solutions into ks
                this.build_model(measurement = asrow(meas_img(idx, :)));
                this.solver_ = this.solver_.solve(@mlkinetics.TwoTCModel.loss_function);
                ks_mat_(idx, :) = [asrow(this.solver_.product.ks), this.solver_.loss];

                if idx < 10
                    fprintf("%s, idx->%i, uindex->%i:", stackstr(), idx, uindex(idx))
                    toc
                end

                if any(idx == this.indicesToCheck)  
                    h = this.solver_.plot();
                    saveFigure2(h, ...
                        this.fqfp + "_" + this.stackstr() + "_uindex" + uindex(idx), ...
                        closeFigure=true);
                end                    
            end

            ks_mat_ = single(ks_mat_);
            soln = this.product.selectImagingTool(img=ks_mat_);
            soln = this.reshape_from_parc(soln);
            soln.fqfp = this.fqfp(tag="huangks");
            this.product_ = soln;            
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
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.TwoTCModel(varargin{:});

            this.LENK = 4;
        end

        %% builder methods for model

        function loss = loss_function(ks, Data, artery_interpolated, times_sampled, measurement, timeCliff)
            import mlkinetics.TwoTCModel.sampled            
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
            
            qs = mlkinetics.TwoTCModel.solution(ks, Data, artery_interpolated);
            qs = mlkinetics.TwoTCModel.solutionOnScannerFrames(qs, times_sampled);
        end
        function qs   = solution(ks, Data, artery_interpolated)
            %  @param artery_interpolated is uniformly sampled at high sampling freq. starting at time = 0.

            ad = mlaif.AifData.instance();
            tBuffer = ad.tBuffer;
            
            K1 = ks(1);
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
            q2 = (K1 / bminusa)      * conv2;
            q3 = (k3 * K1 / bminusa) * conv3;
            qs = artery_interpolated1 + scale*(q2 + q3); 
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
