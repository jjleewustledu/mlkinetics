classdef AbstractC11GlucoseKinetics < mlkinetics.AbstractGlucoseKinetics
	%% ABSTRACTC11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		LC = 1
        LAMBDA_BLOOD = 0.7 % Dillon RS. Importance of the hematocrit in interpretation of blood sugar. Diabetes 1965;14:672-674
    end
    
    properties
        k04 = nan
        k12frac = 0.235563
        k21 = 0.046545
        k32 = 0.008314
        k43 = 0.000263
        t0  = -52.286431
        
        notes = ''
        pnumber
        scanIndex
        xLabel = 'times/s'
        yLabel = 'concentration/(wellcounts/mL)'        
        
        region
        summary
    end
    
    properties (Dependent)
        detailedTitle
        gluTxlsxFilename
        k12
        mapParams
        VB
        FB
        K04
    end
    
    methods (Static)
        function [this,lg] = doBayes
            this.filepath = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlkinetics', 'data', '');
            cd(this.filepath);
            this = mlkinetics.AbstractC11GlucoseKinetics({}, {});
            [this,lg] = this.doItsBayes;
        end
        function Q_sampl = model(k04, k12frac, k21, k32, k43, t0, dta, VB, t_sampl)
            t      = dta.timeInterpolants; % use interpolants internally            
            t0_idx = floor(abs(t0)/dta.dt) + 1;
            if (t0 < -1) % shift cart earlier in time
                cart                 = dta.wellCountInterpolants(end) * ones(1, length(t));
                cart(1:end-t0_idx+1) = dta.wellCountInterpolants(t0_idx:end); 
            elseif (t0 > 1) % shift cart later in time
                cart             = dta.wellCountInterpolants(1) * ones(1, length(t));
                cart(t0_idx:end) = dta.wellCountInterpolants(1:end-t0_idx+1);
            else
                cart = dta.wellCountInterpolants;
            end
            
            k12 = k21 * k12frac;
            k22 = k12 + k32;
            q1_ = VB * cart;
            q2_ = VB * k21 * exp(-k22*t);
            q3_ = VB * k21 * k32 * (k22 - k43)^-1 * (exp(-k43*t) - exp(-k22*t));
            q4_ = VB * k21 * k32 * k43 * ( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)));
                 
            q234    = conv(q2_ + q3_ + q4_, cart);
            Q       = q1_ + q234(1:length(t)); % truncate convolution         
            Q_sampl = pchip(t, Q, t_sampl); % resample interpolants
        end
        function this    = simulateMcmc(k04, k12frac, k21, k32, k43, t0, dta, VB, t, mapParams, keysParams)
            mdl = mlkinetics.AbstractC11GlucoseKinetics.model(k04, k12frac, k21, k32, k43, t0, dta, VB, t);
            this = AbstractC11GlucoseKinetics({t}, {mdl});
            this.mapParams_ = mapParams;
            this.keysParams_ = keysParams;
            [this,lg] = this.doItsBayes;
            fprintf('%s\n', char(lg));
        end
        
        function Cwb = plasma2wb(Cp, hct, ~)
            if (hct > 1)
                hct = hct/100;
            end
            lambda = mlkinetics.AbstractC11GlucoseKinetics.LAMBDA_BLOOD;
            Cwb = Cp.*(1 + hct*(lambda - 1));
        end
        function Cp  = wb2plasma(Cwb, hct, ~)
            if (hct > 1)
                hct = hct/100;
            end
            lambda = mlkinetics.AbstractC11GlucoseKinetics.LAMBDA_BLOOD;
            Cp = Cwb./(1 + hct*(lambda - 1));
        end
    end
    
    methods 
        
        %% GET, SET
        
        function dt   = get.detailedTitle(this)
            dt = sprintf('%s:\nk04 %g, k21 %g, k12frac %g, k32 %g, k43 %g, t0 %g, VB %g, FB %g', ...
                         this.baseTitle, ...
                         this.k04, this.k21, this.k12frac, this.k32, this.k43, this.t0, this.VB, this.FB);
        end
        function fn   = get.gluTxlsxFilename(~)
            fn = fullfile(getenv('ARBELAEZ'), 'GluT', 'GluT de novo 2015aug11.xlsx');
        end 
        function k    = get.k12(this)
            k = this.k12frac*this.k21;
        end
        function this = set.mapParams(this, m)
            assert(isa(m, 'containers.Map'));
            this.mapParams_ = m;
        end
        function m    = get.mapParams(this)
            if (~isempty(this.mapParams_))
                m = this.mapParams_;
                return
            end
            
            m = containers.Map;
            fL = 1; fH = 1;
            
            m('k04')     = struct('fixed', 1, 'min', 0*fL,       'mean', this.K04,     'max', 1*fH); 
            m('k12frac') = struct('fixed', 0, 'min', 0.0387*fL,  'mean', this.k12frac, 'max', 0.218*3);   % Powers' monkey paper
            m('k21')     = struct('fixed', 0, 'min', 0.0435*fL,  'mean', this.k21,     'max', 0.0942*fH);  % "
            m('k32')     = struct('fixed', 0, 'min', 0.0015*fL,  'mean', this.k32,     'max', 0.5589*fH);  % " excluding last 2 entries
            m('k43')     = struct('fixed', 0, 'min', 2.03e-4*fL, 'mean', this.k43,     'max', 3.85e-4*fH); % "
            m('t0' )     = struct('fixed', 0, 'min',-2e2*fL,     'mean', this.t0,      'max', 2e2*fH);  
        end
        function v    = get.VB(this)
            v = 0.041;
            
            % fraction
            %v = this.gluTxlsxInfo.cbv;
            if (v > 1)
                v = v/100; end
        end
        function f    = get.FB(this)
            f = 55;
            
            % fraction/s
            %f = this.gluTxlsxInfo.cbf;
            assert(~isnumeric(f) || ~isnan(f), 'mlkinetics:nan', 'AbstractC11GlucoseKinetics.get.FB');
            f = 1.05 * f / 6000; % mL/min/100g to 1/s
        end
        function k    = get.K04(this)
            % 1/s
            k = this.FB/this.VB;
        end
        
        %% 
        
        function this = prepareScannerData(this)
        end
        function this = prepareAifData(this)
        end
        function ed   = estimateDataFast(this, k04, k12frac, k21, k32, k43, t0)
            %% ESTIMATEDATAFAST is used by AbstractBayesianStrategy.theSolver.
            
            ed{1} = mlkinetics.AbstractC11GlucoseKinetics.model(k04, k12frac, k21, k32, k43, t0, this.dta, this.VB, this.times{1});
        end
        function lg   = logging(this)
            lg = mlpipeline.Logger(this.fqfileprefix);
            if (isempty(this.summary))
                return
            end
            s = this.summary;
            lg.add('\n%s is working in %s\n', mfilename, pwd);
            lg.add('\begin{alignat*}');
            if (~isempty(this.theSolver))
                lg.add('bestFitParams\qty(\qty[k_{04} \text{frac}\qty(k_{12}) k_{21} k_{32} k_{43} t_0]) &-> %s \text{s^{-1}}\n', mat2str(s.bestFitParams));
                lg.add('meanParams   \qty(\qty[k_{04} \text{frac}\qty(k_{12}) k_{21} k_{32} k_{43} t_0]) &-> %s \text{s^{-1}}\n', mat2str(s.meanParams));
                lg.add('stdParams    \qty(\qty[k_{04} \text{frac}\qty(k_{12}) k_{21} k_{32} k_{43} t_0]) &-> %s \text{s^{-1}}\n', mat2str(s.stdParams));
                lg.add('anneal sdpar \qty(\qty[k_{04} \text{frac}\qty(k_{12}) k_{21} k_{32} k_{43} t_0]) &-> %s \text{min^{-1}}\n', mat2str(s.annealingSdparMin));
            end
            lg.add('\text{LC}                                                                &-> %s\n', mat2str(s.LC));
            lg.add('[k_{04} k_{12} k_{21} k_{32} k_{43}]                                     &-> %s \text{min^{-1}}\n', mat2str(s.kmin));
            lg.add('t_0                                                                      &-> %s \text{s^{-1}}', mat2str(s.t0));
            lg.add('chi = frac{k_{21} k_{32}}{k_{12} + k_{32}}                               &-> %s \text{min^{-1}}\n', mat2str(s.chi));
            lg.add('K_d = K_1 = V_B k_{21}                                                   &-> %s \text{mL / (min hg)}\n', mat2str(s.Kd)); 
            lg.add('\operatornameCTX_{\text{glc}} = \qty[\text{glc}] K_1                     &-> %s \text{\mu mol / (min hg)}\n', mat2str(s.CTX)); 
            lg.add('\operatorname{CMR}_{\text{glc}} = \qty[\text{glc}]_{\text{WB}} V_B \chi  &-> %s \text{\mu mol / (min hg)}\n', mat2str(s.CMR));
            lg.add('\text{free glc} = \frac{\operatorname{CMR}_{\text{glc}}}{100 k_{32}}     &-> %s \text{\mu mol / g}\n', mat2str(s.free));
            lg.add('E_{\text{net}} = \frac{\chi\operatorname{CBV}}{\operatorname{CBV}}       &-> %s\n', mat2str(s.Enet));
            lg.add('mask count   &-> %i\n', s.maskCount);
            lg.add('parcellation &-> %s\n', s.parcellation);
            lg.add('bloodGlucose &-> %s\n', s.bloodGlucose);
            lg.add('Hct          &-> %g \text{mg/dL}\n', s.hct);
            lg.add('\end{alignat*}');
            lg.add('\n');
        end
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
                case 'k04'
                    for v = 1:length(vars)
                        args{v} = { vars(v)  this.k12frac this.k21 this.k32 this.k43 this.t0 };  %#ok<*AGROW>
                    end
                case 'k12frac'
                    for v = 1:length(vars)
                        args{v} = { this.k04 vars(v)      this.k21 this.k32 this.k43 this.t0 };
                    end
                case 'k21'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac vars(v) this.k32 this.k43 this.t0 }; 
                    end
                case 'k32'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 vars(v)  this.k43 this.t0 };
                    end
                case 'k43'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 this.k32 vars(v)  this.t0 }; 
                    end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 this.k32 this.k43 vars(v) }; 
                    end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = simulateItsMcmc(this)
            this = mlkinetics.AbstractC11GlucoseKinetics.simulateMcmc( ...
                this.k04, this.k12frac, this.k21, this.k32, this.k43, this.t0, this.dta, this.VB, this.times{1}, this.mapParams_, this.keysParams_);
        end   
        function sse  = sumSquaredErrors(this, p)
            %% SUMSQUAREDERRORS returns the sum-of-square residuals for all cells of this.dependentData and 
            %  corresponding this.estimateDataFast.  
            
            p   = num2cell(p);
            sse = 0;
            edf = this.estimateDataFast(p{:});
            for iidx = 1:length(this.dependentData)
                sse = sse + ...
                      sum( (this.dependentData{iidx} - edf{iidx}).^2 );
            end
            if (sse < 10*eps)
                sse = sse + (1 + rand(1))*10*eps; 
            end
        end
        function this = updateSummary(this)
            s.class = class(this);
            s.datestr = mydatetimestr(now);
            if (~isempty(this.theSolver))
                s.bestFitParams     = this.bestFitParams;
                s.meanParams        = this.meanParams;
                s.stdParams         = this.stdParams;
                s.annealingSdparMin = [60 1 60 60 60] .* this.annealingSdpar;
            end
            s.FB   = this.FB;
            s.VB   = this.VB;
            s.LC   = this.LC;
            s.kmin = 60*[this.k12 this.k21 this.k32 this.k43 this.k04]; % s -> min
            s.t0   = this.t0; % s
            s.chi  = s.kmin(1)*s.kmin(3)/(s.kmin(2) + s.kmin(3));
            s.Kd   = 100*this.v1*s.kmin(1);
            s.CTX  = this.bloodGlucose*s.Kd;
            s.CMR  = this.bloodGlucose*(100*this.v1)*(1/s.LC)*s.chi;
            s.free = s.CMR/(100*s.kmin(3));
            s.Enet = s.chi/s.kmin(5);
            s.maskCount = nan;
            if (~isempty(this.mask))
                mnii = mlfourd.MaskingNIfTId(this.mask.niftid);
                s.maskCount = mnii.count;
            end
            s.parcellation = this.sessionData.parcellation;
            s.bloodGlucose = this.bloodGlucose;
            s.hct          = this.hct;
            this.summary = s;
        end
        
 		function this = AbstractC11GlucoseKinetics(t, y, dta, pnum, snum, varargin)
 			%% ABSTRACTC11GLUCOSEKINETICS
 			%  Usage:  this = AbstractC11GlucoseKinetics()

 			this = this@mlkinetics.AbstractGlucoseKinetics(t, y);            
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 't', @iscell);
            addRequired(ip, 'y', @iscell);
            addRequired(ip, 'dta', @(x) isa(x, 'mlpet.IWellData') || isa(x, 'mlpet.IAifData'));
            addRequired(ip, 'pnum', @(x) lstrfind(x, 'p') | lstrfind(x, 'M'));
            addRequired(ip, 'snum', @isnumeric);
            addParameter(ip, 'region', '', @ischar);
            parse(ip, t, y, dta, pnum, snum, varargin{:});
            
            this.dta       = ip.Results.dta;
            this.pnumber   = ip.Results.pnum;
            this.scanIndex = ip.Results.snum;
            this.region    = ip.Results.region;            
            this.k04       = this.K04;            
            
            this.keysParams_ = {'k04' 'k12frac' 'k21' 'k32' 'k43' 't0'};
            this.keysArgs_   = {this.k04 this.k12frac this.k21 this.k32 this.k43 this.t0};
 		end
 	end 

    %% PROTECTED

    properties (Access = 'protected')
        gluTxlsx_     
    end
    
    methods (Access = 'protected')
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

