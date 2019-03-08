classdef AbstractF18DeoxyGlucoseKinetics < mlkinetics.AbstractGlucoseKinetics
	%% ABSTRACTF18DEOXYGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 21-Jan-2016 16:55:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Abstract)
        LC
    end
    
    properties
        fu = 1 % bolus factor for scanner data
        % Joanne Markham used the notation K_1 = V_B*k_{21}, rate from compartment 1 to 2.
        % Mean values from Powers xlsx "Final Normals WB PET PVC & ETS"
        k1 = 0.304 %3.946/60
        k2 = 0.159 %0.3093/60
        k3 = 0.0274 %0.1862/60
        k4 = 0.01382/60
        u0 = -11.9 %-13      %0 % offset of scanner data w.r.t. blood sampling data
        v1 = 0.0383
        
        sk1 = 1.254/60
        sk2 = 0.4505/60
        sk3 = 0.1093/60
        sk4 = 0.004525/60
        
        arterialNyquist
        scannerNyquist
        summary
    end
    
    properties (Dependent)
        detailedTitle
        mapParams
    end
    
    methods (Static)
        function q      = qpet(Aa, fu, k1, k2, k3, k4, t, v1)
            q = qFDG(Aa, fu, k1, k2, k3, k4, t, v1);
        end
        function mdl    = model(varargin)
            mdl = qFDG(varargin{:});
        end
        function Cp     = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            lambda = mlkinetics.AbstractF18DeoxyGlucoseKinetics.rbcOverPlasma(t);
            Cp = Cwb./(1 + hct*(lambda - 1));
        end
        function Cwb    = plasma2wb(Cp, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            lambda = mlkinetics.AbstractF18DeoxyGlucoseKinetics.rbcOverPlasma(t);
            Cwb = Cp.*(1 + hct*(lambda - 1));
        end
    end
    
	methods
        
        %% GET
        
        function dt   = get.detailedTitle(this)
            dt = sprintf('%s\nLC %g, fu %g, k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g\n%S', ...
                         this.baseTitle, ...
                         this.LC, this.fu, this.k1, this.k2, this.k3, this.k4, this.u0, this.v1, this.notes);
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
            N = 80;
            
            % From Powers xlsx "Final Normals WB PET PVC & ETS"
            m('fu') = struct('fixed', 0, 'min', 0.2,                               'mean', this.fu, 'max',   5);  
            m('k1') = struct('fixed', 0, 'min', 0.05/60,                           'mean', this.k1, 'max',  20/60);
            m('k2') = struct('fixed', 0, 'min', max(0.04517/60   - N*this.sk2, 0), 'mean', this.k2, 'max',   1.7332/60   + N*this.sk2);
            m('k3') = struct('fixed', 0, 'min', max(0.05827/60   - N*this.sk3, 0), 'mean', this.k3, 'max',   0.41084/60  + N*this.sk3);
            m('k4') = struct('fixed', 0, 'min', max(0.0040048/60 - N*this.sk4, 0), 'mean', this.k4, 'max',   0.017819/60 + N*this.sk4);
            m('u0') = struct('fixed', 0, 'min', -100,                              'mean', this.u0, 'max', 100);  
            m('v1') = struct('fixed', 1, 'min', 0.01,                              'mean', this.v1, 'max',   0.1);  
        end
        
        %%
         
        function [this,lg] = doItsBayes(this, varargin)
            %% DOITSBAYES
            %  @param named adjustment is char:  e.g., nBeta>= 50, nAnneal >= 20.
            %  @param named value is integer.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'adjustment', '', @ischar);
            addParameter(ip, 'value', nan, @isnumeric);
            parse(ip, varargin{:});
            this.parameterToAdjust_ = ip.Results.adjustment;
            this.adjustmentValue_   = ip.Results.value;
            
            tic
            this = this.estimateParameters;
            this.plot;
            saveFigures(sprintf('fig_%s', this.fileprefix));            
            this = this.updateSummary;
            this.save;
            this.writetable;
            lg = this.logging;
            lg.save('w');   
            fprintf('%s.doItsBayes:', class(this));
            fprintf('%s\n', char(lg));  
            fprintf('%s.doItsBayes:  completed work in %s\n', class(this), pwd);
            toc
        end
        function [this,lg] = doItsBayesQuietly(this)
            this = this.makeQuiet;
            this = this.estimateParameters;
            this.plot;
            saveFigures(sprintf('fig_%s', this.fileprefix));            
            this = this.updateSummary;
            this.save;
            this.writetable;
            lg = this.logging;
            lg.save('w');
        end
        function this = updateSummary(this)
            s.class = class(this);
            s.datestr = mydatetimestr(now);
            if (~isempty(this.theSolver))
                s.bestFitParams = this.bestFitParams;
                s.meanParams = this.meanParams;
                s.stdParams  = this.stdParams;
                s.annealingSdparMin = 60*this.annealingSdpar;
            end
            s.kmin = 60*[this.k1 this.k2 this.k3 this.k4];
            s.LC = this.LC;
            s.chi = s.kmin(1)*s.kmin(3)/(s.kmin(2) + s.kmin(3));
            s.Kd = 100*this.v1*s.kmin(1);
            s.CTX = this.bloodGlucose*s.Kd;
            s.CMR = this.bloodGlucose*(100*this.v1)*(1/s.LC)*s.chi;
            s.free = s.CMR/(100*s.kmin(3));    
            s.maskCount = nan;
            if (~isempty(this.mask))
                mnii = mlfourd.MaskingNIfTId(this.mask.niftid);
                s.maskCount = mnii.count;
            else
                s.maskCount = nan;
            end
            s.parcellation = this.sessionData.parcellation;
            s.hct = this.hct;
            this.summary = s;
        end
        function lg   = logging(this)
            lg = mlpipeline.Logger(this.fqfileprefix);
            if (isempty(this.summary))
                return
            end
            s = this.summary;
            lg.add('\n%s is working in %s\n', mfilename, pwd);
            if (~isempty(this.theSolver))
                lg.add('bestFitParams / s^{-1} -> %s\n', mat2str(s.bestFitParams));
                lg.add('meanParams / s^{-1} -> %s\n', mat2str(s.meanParams));
                lg.add('stdParams / s^{-1} -> %s\n', mat2str(s.stdParams));
                lg.add('std([[k_1 ... k_4]] / min^{-1}) -> %s\n', mat2str(s.annealingSdparMin));
            end
            lg.add('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(s.kmin));
            lg.add('LC -> %s\n', mat2str(s.LC));
            lg.add('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(s.chi));
            lg.add('K_d = K_1 = V_B k1 / (mL min^{-1} hg^{-1}) -> %s\n', mat2str(s.Kd)); 
            lg.add('CTX_{glc} = [glc] K_1 / (\\mu mol min^{-1} hg^{-1}) -> %s\n', mat2str(s.CTX)); 
            lg.add('CMR_{glc} = [glc] V_B chi / (\\mu mol min^{-1} hg^{-1}) -> %s\n', mat2str(s.CMR));
            lg.add('free glc = CMR_{glc}/(100 k_3) / (\\mu mol/g) -> %s\n', mat2str(s.free));
            lg.add('mnii.count -> %i\n', s.maskCount);
            lg.add('sessd.parcellation -> %s\n', s.parcellation);
            lg.add('sessd.hct -> %g\n', s.hct);
            lg.add('\n');
        end
        function mdl  = itsQpet(this)
            mdlCell = this.estimateDataFast(this.keysArgs_{:});
            mdl = mdlCell{1};
        end
        function ed   = estimateDataFast(this, fu, k1, k2, k3, k4, u0, v1)
            %% ESTIMATEDATAFAST is used by AbstractBayesianStrategy.theSolver.
            
            tNyquist = this.arterialNyquist.times;
            qNyquist = qFDG( ...
                this.arterialNyquist.specificActivity, fu, k1, k2, k3, k4, tNyquist, v1);
            ed{1}    = this.pchip(tNyquist, qNyquist, this.tsc.times, u0);
        end
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (ps(theParams.paramsIndices('k4')) > ps(theParams.paramsIndices('k3')))
                tmp                               = ps(theParams.paramsIndices('k3'));
                ps(theParams.paramsIndices('k3')) = ps(theParams.paramsIndices('k4'));
                ps(theParams.paramsIndices('k4')) = tmp;
            end
        end
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
                case 'k1'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.k2 this.k3 this.k4 this.u0 this.v1};  %#ok<*AGROW>
                    end
                case 'k2'
                    for v = 1:length(vars)
                        args{v} = { this.k1 vars(v) this.k3 this.k4 this.u0 this.v1}; 
                    end
                case 'k3'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 vars(v) this.k4 this.u0  this.v1}; 
                    end
                case 'k4'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 vars(v) this.u0 this.v1}; 
                    end
                case 'u0'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 this.k4 vars(v) this.v1};
                    end
                case 'v1'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 this.k4 this.u0 vars(v)}; 
                    end
            end
            this.plotParArgs(par, args, vars);
        end
        function        writetable(this, varargin)
            ip = inputParser;
            addParameter(ip, 'fqfp', this.fqfileprefix, @ischar);
            addParameter(ip, 'Sheet', 1, @isnumeric);
            addParameter(ip, 'Range', 'A3:V3', @ischar);
            addParameter(ip, 'writeHeader', true, @islogical);
            parse(ip, varargin{:}); 
            
            summ = this.summary;
            
            if (ip.Results.writeHeader)
                H = cell2table({'subject', 'visit', 'ROI', 'plasma glu (mg/dL)', 'Hct', 'WB glu (mmol/L)', 'CBV (mL/100g)', ...
                     'k1 (1/s)', 'std(k1)', 'k2 (1/s)', 'std(k2)', 'k3 (1/s)', 'std(k3)', 'k4 (1/s)', 'std(k4)', ...
                     't_offset (s)', 'std(t_offset)', 'chi', 'Kd', 'CTXglu', 'CMRglu', 'free glucose'});
                writetable(H, [ip.Results.fqfp '.xlsx'], ...
                    'Sheet', ip.Results.Sheet, 'Range', 'A2:V2', 'WriteVariableNames', false);
            end
            
            subjid = this.sessionData.sessionFolder;
            sp = summ.stdParams;
            v = 0;
            roi = this.translateYeo7(this.sessionData.parcellation); 
            T = cell2table({subjid, v, roi, this.sessionData.plasmaGlucose, summ.hct, this.bloodGlucose, 100*this.v1, ...
                this.k1, sp(2), this.k2, sp(3), this.k3, sp(4), this.k4, sp(5), this.u0, sp(6), ...
                summ.chi, summ.Kd, summ.CTX, summ.CMR, summ.free});
            writetable(T, [ip.Results.fqfp '.xlsx'], ...
                'Sheet', ip.Results.Sheet, 'Range', ip.Results.Range, 'WriteVariableNames', false);
        end   
        
 		function this = AbstractF18DeoxyGlucoseKinetics(varargin)
 			%% ABSTRACTF18DEOXYGLUCOSEKINETICS
 			%  Usage:  this = AbstractF18DeoxyGlucoseKinetics() 			
 			
 			this = this@mlkinetics.AbstractGlucoseKinetics();
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'mask',        varargin{1}.aparcAsegBinarized('typ','mlfourd.ImagingContext'), ...
                                            @(x) isa(x, 'mlfourd.ImagingContext') || isempty(x));
            addParameter(ip, 'tsc',         []);
            addParameter(ip, 'dta',         []);
            addParameter(ip, 'filepath',    varargin{1}.tracerLocation, @isdir);
            parse(ip, varargin{:});
            this.sessionData = ip.Results.sessionData;
            assert(strcmp(this.sessionData.tracer, 'FDG'));
            assert(       this.sessionData.attenuationCorrected);
            this.filepath    = ip.Results.filepath;
            this.fileprefix  = sprintf('%s_%s', strrep(class(this), '.', '_'), this.sessionData.parcellation);
            this.mask        = ip.Results.mask;
            this.tsc         = ip.Results.tsc;
            this.dta         = ip.Results.dta;
            if (~this.dta.isPlasma)
                this.dta.specificActivity = ...
                    mlkinetics.AbstractF18DeoxyGlucoseKinetics.wb2plasma(this.dta.specificActivity, this.hct, this.dta.times);
                this.dta.isPlasma = true;
            end
            if (isempty(ip.Results.tsc) && isempty(ip.Results.dta))
                this.tsc_ = this.dta.scannerData;
            end
            
            assert(isvector(this.tsc.times));            
            assert(isvector(this.tsc.specificActivity));
            this.independentData = {ensureRowVector(this.tsc.times)};
            this.dependentData   = {ensureRowVector(this.tsc.specificActivity)};            
            [t,dtaBecq1,tscBecq1] = ...
                this.interpolateAll( ...
                    this.dta.times, this.dta.specificActivity, ...
                    this.tsc.times, this.tsc.specificActivity);
            this.arterialNyquist = struct('times', t, 'specificActivity', dtaBecq1);
            this.scannerNyquist  = struct('times', t, 'specificActivity', tscBecq1);
            this.keysParams_ = {'fu' 'k1' 'k2' 'k3' 'k4' 'u0' 'v1'};
            this.keysArgs_   = {this.fu this.k1 this.k2 this.k3 this.k4 this.u0 this.v1};            
            %this = this.buildJeffreysPrior;
        end        
 
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
    end
    
    methods (Access = 'protected')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlkinetics.AbstractF18DeoxyGlucoseKinetics')));
            assert(iscell(args));
            assert(isnumeric(vars));
            figure
            hold on
            Aa = this.dta.specificActivity;
            plot(0:length(Aa)-1, Aa, 'o')
            for v = 1:length(args)
                argsv = args{v};
                plot(0:length(Aa)-1, ...
                     qFDG( ...
                         Aa, argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, this.times{1}, argsv{6}));
            end
            plot(0:length(Aa)-1, this.dependentData{1}, 'LineWidth', 2);
            title(sprintf('k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            region = 'WB';
            if (~isempty(this.mask))
                region = this.mask.fileprefix;
            end
            legend(['bayes' ...
                    cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false) ...
                    region]);
            xlabel('time sampling index');
            ylabel(this.yLabel);
        end
        function rsn = translateYeo7(~, roi)
            try
                switch (roi)
                    case 'yeo1'
                        rsn = 'visual';
                    case 'yeo2'
                        rsn = 'somatomotor';
                    case 'yeo3'
                        rsn = 'dorsal attention';
                    case 'yeo4'
                        rsn = 'ventral attention';
                    case 'yeo5'
                        rsn = 'limbic';
                    case 'yeo6'
                        rsn = 'frontoparietal';
                    case 'yeo7'
                        rsn = 'default';
                    otherwise
                        rsn = roi;
                end
            catch ME %#ok<NASGU>
                rsn = '';
            end
        end
    end
    
    %% PRIVATE
    
    methods (Static, Access = 'private')
        function rop = rbcOverPlasma(t)
            %% RBCOVERPLASMA is [FDG(RBC)]/[FDG(plasma)]
            
            t   = t/60;      % sec -> min
            a0  = 0.814104;  % FINAL STATS param  a0 mean  0.814192	 std 0.004405
            a1  = 0.000680;  % FINAL STATS param  a1 mean  0.001042	 std 0.000636
            a2  = 0.103307;  % FINAL STATS param  a2 mean  0.157897	 std 0.110695
            tau = 50.052431; % FINAL STATS param tau mean  116.239401	 std 51.979195
            rop = a0 + a1*t + a2*(1 - exp(-t/tau));
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

