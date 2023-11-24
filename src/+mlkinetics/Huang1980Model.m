classdef (Sealed) Huang1980Model < handle & mlkinetics.TCModel
    %% line1
    %  line2
    %  
    %  Created 13-Jun-2023 22:30:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        glc
        hct
        LC
    end

    properties (Dependent)
        use_external_v1
        v1_ic
    end

    methods %% GET
        function g = get.use_external_v1(this)
            g = isfield(this.data.cbv_ic);
        end
        function g = get.v1_ic(this)
            if this.use_external_v1
                g = this.data.cbv_ic;
                g = g/mlkinetics.OxyMetabConversion.DENSITY_BRAIN;
                g = g/100;
                return
            end
            g = [];
        end
    end

    methods
        function this = buildModel(this, opts)
            arguments
                this mlkinetics.Huang1980Model
                opts.glc double = 100
                opts.hct double = 0.4375
                opts.LC double = 0.81
                opts.map containers.Map = this.preferredMap()
                opts.times_sampled double = []
                opts.artery_interpolated double = []
                opts.solver_tags = "simulanneal"
            end
            if (opts.hct > 1)
                opts.hct = opts.hct/100;
            end 

            this.glc = opts.glc;
            this.hct = opts.hct;
            this.LC = opts.LC;
            this.map = opts.map;
            this = set_times_sampled(this, opts.times_sampled);
            this = set_artery_interpolated(this, opts.artery_interpolated);
            
            if contains(opts.solver_tags, "simulanneal")
                this.solver_ = mlglucose.Huang1980SimulAnneal(context=this);
            end
            if contains(opts.solver_tags, "multinext")
                this.solver_ = mlglucose.Huang1980MultiNest(context=this);
            end
            if contains(opts.solver_tags, "skilling-nest")
                this.solver_ = mlglucose.Huang1980Nest(context=this);
            end
        end
        function buildParcellation(this)
        end
        function buildSolved(this)
        end
        function r = cmrglc(this, varargin)
            %  @return umol/hg/min
            
            % [umol/mmol] [(mmol/L) / (mg/dL)] [L/dL] [dL/mL] [g/hg] [mL/g] == [umol/hg]
            glc_ = this.trcMassConversion(this.glc, 'mg/dL', 'umol/hg'); 
            r = 60*this.chi(varargin{:})*glc_/this.model.LC;
        end
        function c = chi(this, varargin)
            %  @return 1/s
            
            if this.use_external_v1
                K1_ = this.v1*k1(this, varargin{:});
            else
                K1_ = K1(this, varargin{:});
            end
            c = K1_.*k3(this, varargin{:})./ ...
                (k2(this, varargin{:}) + k3(this, varargin{:}));
        end
        function [K,sK] = K1(this, varargin)
            [K,sK] = K1(this.solver_, varargin{:});
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
        function soln = make_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.
            %  @return aifs_ in R^(1+1), without saving.
            
            import mlglucose.DispersedNumericHuang1980                                    

            aifs_img_ = zeros([size(wmparc1) lenInputFunc], 'single');
            ks_img_ = zeros([size(wmparc1) this.LENK], 'single');
            indices_ = this.indices;
            this_roiOnAtlas_ = @this.roiOnAtlas;
            this_indicesToCheck_ = this.indicesToCheck;
            this_savefig_ = @this.savefig;
            models = cell(size(indices_));
            for ii = 1:length(indices_) % parcs
 
                idx = indices_(ii);

                tic 

                % for parcs, build roibin as logical, roi as single 
                %fprintf('%s\n', datestr(now))
                fprintf('starting mlkinetics.Huang1980Model.buildModel.idx -> %i\n', idx)

                % solve Huang
                huang = DispersedNumericHuang1980.createFromDeviceKit( ...
                    this.scanner_kit_, ...
                    'scanner', scanner, ...
                    'arterial', arterial, ...
                    'cbv', this.data.cbv_ic, ...
                    'roi', roi); 
                    % arterial must be cell to dispatch to DispersedNumericHuang1980.createFromDualDeviceKit()
                huang = huang.solve(@mlglucose.DispersedHuang1980Model.loss_function);
                models{ii} = huang.model;

                % insert Huang solutions into ks
                ks_img_ = ks_img_ + huang.ks_mediated().img;
                
                % collect delay & dispersion adjusted aifs
                aifs_img_ = aifs_img_ + huang.artery_local_mediated().img;

                toc

                % Dx
                
                if any(idx == this_indicesToCheck_)  
                    h = huang.plot();
                    this_savefig_(h, idx)
                end                    
            end
            this.model = models{end};

            ks_ = wmparc1.nifti;
            ks_.filepath = this.scanPath;
            ic = this.ksOnAtlas(tags=this.tags);
            ks_.fileprefix = ic.fileprefix; 
            ks_.img = ks_img_;
            ks_ = mlfourd.ImagingContext2(ks_);
            ks_.ensureSingle();

            aifs_ = copy(ks_);
            ic = this.aifsOnAtlas(tags=this.tags);
            aifs_.fileprefix = ic.fileprefix;
            aifs_.img = aifs_img_;            
            aifs_ = mlfourd.ImagingContext2(aifs_);
            aifs_.ensureSingle();
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Huang1980Model(varargin{:});

            this.LENK = 5;
            this.mgdL_to_mmolL = 0.0555;
            [this.measurement_,this.times_sampled_,this.t0_,this.artery_interpolated_] = this.mixTacAif();

            assert(isfield(this.data_, "cbv"), ...
                "%s: data_ is missing cbv", stackstr())

            % apply kinetics assumptions
            this.buildParcellation();
            try
                radm = this.tracer_kit_.make_handleto_counter();
                this.buildModel( ...
                    glc=this.glcFromRadMeasurements(radm), ...
                    hct=this.hctFromRadMeasurements(radm));
            catch ME
                handwarning(ME)
                this.buildModel();
            end
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
        function loss = loss_function(ks, v1, artery_interpolated, times_sampled, measurement, ~)
            import mlkinetics.Huang1980Model.sampled            
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
            
            import mlkinetics.Huang1980Modell.solution 
            import mlkinetics.Huang1980Model.solutionOnScannerFrames  
            qs = solution(ks, v1, artery_interpolated);
            qs = solutionOnScannerFrames(qs, times_sampled);
        end
        function qs   = solution(ks, v1, artery_interpolated)
            %  @param artery_interpolated is uniformly sampled at high sampling freq. starting at time = 0.

            tBuffer = 0;
            
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
