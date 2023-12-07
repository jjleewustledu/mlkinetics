classdef Raichle1983Model < handle & mlkinetics.TCModel
    %% line1
    %  line2
    %  
    %  Created 13-Jun-2023 22:30:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        ks_names = {'f', '\lambda', 'ps', '\Delta'}
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

            this.map = opts.map;
            if ~isempty(opts.measurement)
                this.measurement_ = opts.measurement;
            end
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mloxygen.Raichle1983SimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinest")
                this.solver_ = mloxygen.Raichle1983MultiNest(context=this);
            end
            if contains(opts.solver_tags, "skilling-nest")
                this.solver_ = mloxygen.Raichle1983Nest(context=this);
            end
        end
        function soln = build_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.                                

            uindex = this.unique_indices;
            Nx = numel(uindex);

            meas_ic = mlfourd.ImagingContext2(this.measurement_);
            meas_ic = this.reshape_to_parc(meas_ic);
            meas_img = double(meas_ic.imagingFormat.img);

            martinv1_ic = this.reshape_to_parc(this.martinv1_ic);
            martinv1_img = double(martinv1_ic.imagingFormat.img);

            ks_mat_ = zeros([Nx this.LENK+1]);
            for idx = 1:Nx % parcs
 
                if idx < 10; tic; end

                % solve Raichle and insert solutions into ks
                this.Data = struct("martinv1", martinv1_img(idx));
                this.build_model(measurement=asrow(meas_img(idx, :)));
                this.solver_ = this.solver_.solve(@mlkinetics.Raichle1983Model.loss_function);
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

            ks_mat_(ks_mat_ < 0) = 0;
            ks_mat_ = single(ks_mat_);
            soln = this.product.selectImagingTool(img=ks_mat_);
            soln = this.reshape_from_parc(soln);
            soln.fqfp = this.fqfp(tag="raichleks");
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

        %% UTILITIES

        function this = adjustMapForHistology(this, histology)
            %% use PS ranges from Herscovitch et al 1987 Table 2
            
            switch histology
                case 'g'
                    this.map('k1') = struct('min', 0.0043, 'max',  0.0155, 'init', 0.00777, 'sigma', 3.89e-4); % f / s, max ~ 0.0155
                    this.map('k2') = struct('min', 0.017,  'max', 0.0266,  'init', 0.0218,  'sigma', 0.002); % PS / s
                    this.map('k3') = struct('min', 0.738,  'max', 1.06,    'init', 1.02,    'sigma', 0.05); % lambda in mL/mL  
                    %this.map('k3') = struct('min', 0.987, 'max', 1.06,    'init', 1.02,    'sigma', 0.05); % lambda in mL/mL                    
                case 'w'
                    this.map('k1') = struct('min', 0.0043, 'max',  0.0155, 'init', 0.00777, 'sigma', 3.89e-4); % f / s, max ~ 0.0155
                    this.map('k2') = struct('min', 0.0137, 'max', 0.0142,  'init', 0.014,   'sigma', 0.002); % PS / s
                    this.map('k3') = struct('min', 0.608,  'max', 0.882,   'init', 0.851,   'sigma', 0.05); % lambda in mL/mL
                    %this.map('k3') = struct('min', 0.819, 'max', 0.882,     'init', 0.851,   'sigma', 0.05); % lambda in mL/mL
                case 's' 
                    % subcortical
                    this.map('k1') = struct('min', 0.0043, 'max',  0.0155, 'init', 0.00777, 'sigma', 3.89e-4); % f / s, max ~ 0.0155
                    this.map('k2') = struct('min', 0.0159, 'max', 0.0215,  'init', 0.0187,  'sigma', 0.002); % PS / s
                    this.map('k3') = struct('min', 0.738,  'max', 0.97,    'init', 0.924,   'sigma', 0.05); % lambda in mL/mL
                case 'c' 
                    % csf, indices 1, 4, 5, 43, 44
                    this.map('k3') = struct('min', 0.1,    'max', 1,       'init', 0.5,     'sigma', 0.05); % lambda in mL/mL
                    this.map('k4') = struct('min', 0.02,   'max', 2,       'init', 0.2,     'sigma', 0.1); % Delta for cerebral dispersion
                case 'v' 
                    % venous, index 6000
                    this.map('k3') = struct('min', 0.05,   'max', 0.6,     'init', 0.1,     'sigma', 0.05); % lambda in mL/mL
                    this.map('k4') = struct('min', 0.5,    'max', 10,      'init', 3,       'sigma', 0.1); % Delta for cerebral dispersion
                otherwise
                    % noninformative
            end
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Raichle1983Model(varargin{:});
            assert(~isempty(this.martinv1_ic), ...
                "%s: data_ is missing martinv1_ic", stackstr())

            this.LENK = 4;
        end

        function E_ = E(PS, f)
            E_ = 1 - exp(-PS/f);
            % E_MIN = 0.7;
            % E_MAX = 0.93;
            % E_ = max(1 - exp(-PS/f), E_MIN);
            % E_ = min(E_, E_MAX);
        end
        function loss = loss_function(ks, Data, artery_interpolated, times_sampled, measurement, timeCliff)
            import mlkinetics.Raichle1983Model.sampled
            estimation  = sampled(ks, Data, artery_interpolated, times_sampled);
            measurement = measurement(1:length(estimation));
            positive    = measurement > 0.05*max(measurement); % & times_sampled < timeCliff;
            eoverm      = estimation(positive)./measurement(positive);
            Q           = mean(abs(1 - eoverm));
            %Q           = mean((1 - eoverm).^2);
            loss        = Q; % 0.5*Q/sigma0^2 + sum(log(sigma0*measurement)); % sigma ~ sigma0*measurement
        end
        function m = preferredMap()
            %% init from Raichle J Nucl Med 24:790-798, 1983; Herscovitch JCBFM 5:65-69 1985; Herscovitch JCBFM 7:527s-542 1987
            %  PS in [0.0140 0.0245 0.0588] Hz for white, brain, grey;
            %  PS min := PS(1) - (PS(2) - PS(1))
            %  PS max := PS(3) + (PS(3) - PS(2))
            %  PS init := PS(2)
            %  PS sigma := 0.08*(PS init)
            %  lambda described in Table 2
            
            m = containers.Map;
            m('k1') = struct('min', 0.0022, 'max',  0.0171, 'init', 0.00777, 'sigma', 3.89e-4); % f / s, max ~ 0.0155
            m('k2') = struct('min', 0.608,  'max',  1.06,   'init', 0.945,   'sigma', 0.05); % lambda in mL/mL
            m('k3') = struct('min', 0.0081, 'max',  0.0293, 'init', 0.0228,  'sigma', 0.002); % PS / s, max ~ 0.0266
            m('k4') = struct('min', 0,      'max',  1,      'init', 0,       'sigma', 0.1); % Delta for cerebral dispersion
        end
        function qs = sampled(ks, Data, artery_interpolated, times_sampled)
            %  @param artery_interpolated is uniformly sampled at high sampling freq.
            %  @param times_sampled are samples scheduled by the time-resolved PET reconstruction
            
            qs = mlkinetics.Raichle1983Model.solution(ks, Data, artery_interpolated);
            qs = mlkinetics.Raichle1983Model.solutionOnScannerFrames(qs, times_sampled);
        end
        function qs = solution(ks, Data, artery_interpolated)
            %  @param artery_interpolated is uniformly sampled with at high sampling freq. starting at time = -tBuffer.
            %         First tBuffer seconds of artery_interpolated are used for modeling but not reported
            %         in returned qs.  
            %  @return qs is the modeled scanner emissions, uniformly sampled.
            
            %ad = mlaif.AifData.instance();
            %tBuffer = ad.tBuffer;
            tBuffer = 0;
            ALPHA = 0.005670305; % log(2)/halflife in 1/s
            
            f = ks(1);
            lambda = ks(2); 
            PS = ks(3);
            Delta = ks(4);
            v1 = Data.martinv1;
            E = mlkinetics.Raichle1983Model.E(PS, f);
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
            
            % use E, f, lambda
            kernel = exp(-E*f*timesb/lambda - ALPHA*timesb);
            qs = E*f*conv(kernel, artery_interpolated1);
            qs = qs(tBuffer+1:n) + v1*artery_interpolated1; % venous volume >> arterial volume
        end  
    end

    %% PROTECTED

    properties (Access = protected)
    end

    methods (Access = protected)
        function this = Raichle1983Model(varargin)
            this = this@mlkinetics.TCModel(varargin{:});     
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
