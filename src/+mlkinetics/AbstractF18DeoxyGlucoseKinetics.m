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
    
    methods (Abstract)
        prepareTsc(this)
        prepareDta(this)
    end
    
    properties
        fu = 1 % FUDGE
        % Joanne Markham used the notation K_1 = V_B*k_{21}, rate from compartment 1 to 2.
        % Mean values from Powers xlsx "Final Normals WB PET PVC & ETS"
        k1 = 3.946/60
        k2 = 0.3093/60
        k3 = 0.1862/60
        k4 = 0.01382/60
        u0 = 0 % offset of scanner data w.r.t. blood sampling data
        v1 = 0.0383
        
        sk1 = 1.254/60
        sk2 = 0.4505/60
        sk3 = 0.1093/60
        sk4 = 0.004525/60
    end
    
    properties (Dependent)
        detailedTitle
        mapParams
    end
    
    methods %% GET
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nfu %g, k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g\n%S', ...
                         this.baseTitle, ...
                         this.fu, this.k1, this.k2, this.k3, this.k4, this.u0, this.v1, this.notes);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            N = 10;
            
            % From Powers xlsx "Final Normals WB PET PVC & ETS"
            m('fu') = struct('fixed', 1, 'min', 0.01,                               'mean', this.fu, 'max',   1);  
            m('k1') = struct('fixed', 0, 'min', max(1.4951/60 - 0.2*N*this.sk1, 0), 'mean', this.k1, 'max',   6.6234/60   + 5*N*this.sk1);
            m('k2') = struct('fixed', 0, 'min', max(0.04517/60    - N*this.sk2, 0), 'mean', this.k2, 'max',   1.7332/60   +   N*this.sk2);
            m('k3') = struct('fixed', 0, 'min', max(0.05827/60    - N*this.sk3, 0), 'mean', this.k3, 'max',   0.41084/60  +   N*this.sk3);
            m('k4') = struct('fixed', 0, 'min', max(0.0040048/60  - N*this.sk4, 0), 'mean', this.k4, 'max',   0.017819/60 +   N*this.sk4);
            m('u0') = struct('fixed', 0, 'min', -100,                               'mean', this.u0, 'max', 100);  
            m('v1') = struct('fixed', 1, 'min', 0.01,                               'mean', this.v1, 'max',   0.1);  
        end
    end
    
    methods (Static)
        function alpha_ = a(k2, k3, k4)
            k234   = k2 + k3 + k4;
            alpha_ = k234 - sqrt(k234^2 - 4*k2*k4);
            alpha_ = alpha_/2;
        end
        function beta_  = b(k2, k3, k4)
            k234  = k2 + k3 + k4;
            beta_ = k234 + sqrt(k234^2 - 4*k2*k4);
            beta_ = beta_/2;
        end
        function q      = q2(Aa, k1, a, b, k4, t)
            scale = k1/(b - a);
            q = scale * conv((k4 - a)*exp(-a*t) + (b - k4)*exp(-b*t), Aa);
            q = q(1:length(t));
        end
        function q      = q3(Aa, k1, a, b, k3, t)
            scale = k3*k1/(b - a);
            q = scale * conv(exp(-a*t) - exp(-b*t), Aa);
            q = q(1:length(t));
        end
        function q      = qpet(Aa, fu, k1, k2, k3, k4, t, v1)
            import mlkinetics.*;
            Aa = v1*Aa;
            a  = AbstractF18DeoxyGlucoseKinetics.a(k2, k3, k4);
            b  = AbstractF18DeoxyGlucoseKinetics.b(k2, k3, k4);
            q  = AbstractF18DeoxyGlucoseKinetics.q2(Aa, k1, a, b, k4, t) + ...
                 AbstractF18DeoxyGlucoseKinetics.q3(Aa, k1, a, b, k3, t) + ...
                 fu*Aa;
        end
        function Cp     = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            lambda = mlkinetics.AbstractF18DeoxyGlucoseKinetics.rbcOverPlasma(t);
            Cp = Cwb./(1 + hct*(lambda - 1));
        end
    end
    
	methods
 		function this = AbstractF18DeoxyGlucoseKinetics(varargin)
 			%% ABSTRACTF18DEOXYGLUCOSEKINETICS
 			%  Usage:  this = AbstractF18DeoxyGlucoseKinetics() 			
 			
 			this = this@mlkinetics.AbstractGlucoseKinetics();
            
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'mask',       varargin{1}.aparcAsegBinarized('typ','mlfourd.ImagingContext'), ...
                                           @(x) isa(x, 'mlfourd.ImagingContext') || isempty(x));
            addParameter(ip, 'hct',        varargin{1}.hct, ...
                                           @isnumeric);
            addParameter(ip, 'dta',        [], ...
                                           @(x) isa(x, 'mlpet.IAifData') || isa(x, 'mlpet.IWellData'));
            addParameter(ip, 'tsc',        [], ...
                                           @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, varargin{:});
            this.sessionData = ip.Results.sessionData;
            if (isempty(ip.Results.mask))
                warning('mlkinetics:parameterIsEmpty', 'AbstractF18DeoxyGlucoseKinetics.mask -> []');
            end
            this.mask = ip.Results.mask;
            this.hct = ip.Results.hct;
            if (this.hct < 1); this.hct = this.hct*100; end
            assert(strcmp(this.sessionData.tracer, 'FDG'));
            assert(this.sessionData.attenuationCorrected);
            
            this.tsc = ip.Results.tsc;
            if (isempty(ip.Results.tsc))
                this.tsc = this.prepareTsc;
            end
            this.dta = ip.Results.dta;
            if (isempty(ip.Results.dta))
                this.dta = this.prepareDta; % accesses this.tsc; KLUDGE side-effect
                this.tsc = this.dta.scannerData;
            end
            this.independentData  = {ensureRowVector(this.tsc.times)};
            this.dependentData    = {ensureRowVector(this.tsc.specificActivity)};            
            this.jeffreysPrior    = this.buildJeffreysPrior;
            [t,dtaBecq1,tscBecq1,this.u0] = this.interpolateAll( ...
                this.dta.times, this.dta.specificActivity, this.tsc.times, this.tsc.specificActivity);
            this.dtaNyquist  = struct('times', t, 'specificActivity', dtaBecq1);
            this.tscNyquist  = struct('times', t, 'specificActivity', tscBecq1);
            this.filepath    = this.sessionData.vLocation;
            this.fileprefix  = sprintf('%s_%s', strrep(class(this), '.', '_'), this.sessionData.parcellation);
            this.expectedBestFitParams_ = ...
                [this.fu this.k1 this.k2 this.k3 this.k4 this.u0 this.v1]';
        end        
        
        function [this,lg] = doBayes(this)
            tic
            
            this = this.estimateParameters;
            this.plotAll;
            saveFigures(sprintf('fig_%s', this.fileprefix));            
            this = this.updateSummary;
            this.save;
            lg = this.logging;
            lg.save('w');   
            this.writetable;
            fprintf('mlkinetics.AbstractF18DeoxyGlucoseKinetics.doBayes:');
            fprintf('%s\n', char(lg));                   
            
            toc
        end
        function [this,lg] = doBayesQuietly(this)
            this = this.makeQuiet;
            this = this.estimateParameters;
            this.plotAll;
            saveFigures(sprintf('fig_%s', this.fileprefix));            
            this = this.updateSummary;
            this.save;
            this.writetable;
            lg = this.logging;
            lg.save('w');
        end
        function this = updateSummary(this)
            summary.class = class(this);
            summary.datestr = datestr(now, 30);
            if (~isempty(this.theSolver))
                summary.bestFitParams = this.bestFitParams;
                summary.meanParams = this.meanParams;
                summary.stdParams  = this.stdParams;
                summary.sdpar = 60*this.annealingSdpar(2:5);
            end
            summary.kmin = 60*[this.k1 this.k2 this.k3 this.k4];
            summary.LC = this.LC;
            summary.chi = summary.kmin(1)*summary.kmin(3)/(summary.kmin(2) + summary.kmin(3));
            summary.Kd = 100*this.v1*summary.kmin(1);
            summary.CMR = (this.v1/0.01)*(1/summary.LC)*summary.chi;
            summary.free = summary.CMR/(100*summary.kmin(3));    
            summary.maskCount = nan;
            if (~isempty(this.mask))
                mnii = mlfourd.MaskingNIfTId(this.mask.niftid);
                summary.maskCount = mnii.count;
            else
                summary.maskCount = nan;
            end
            summary.parcellation = this.sessionData.parcellation;
            summary.hct = this.hct;
            this.summary = summary;
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
                lg.add('std([[k_1 ... k_4]] / min^{-1}) -> %s\n', mat2str(s.sdpar));
            end
            lg.add('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(s.kmin));
            lg.add('LC -> %s\n', mat2str(s.LC));
            lg.add('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(s.chi));
            lg.add('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(s.Kd)); 
            lg.add('CMRglu/[glu] = V_B chi / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(s.CMR));
            lg.add('free glu/[glu] = CMRglu/(100 k3) -> %s\n', mat2str(s.free));
            lg.add('mnii.count -> %i\n', s.maskCount);
            lg.add('sessd.parcellation -> %s\n', s.parcellation);
            lg.add('sessd.hct -> %g\n', s.hct);
            lg.add('\n');
        end
        function a    = itsA(this)
            a = mlkinetics.AbstractF18DeoxyGlucoseKinetics.a(this.k2, this.k3, this.k4);
        end
        function b    = itsB(this)
            b = mlkinetics.AbstractF18DeoxyGlucoseKinetics.b(this.k2, this.k3, this.k4);
        end
        function q2   = itsQ2(this)
            q2 = mlkinetics.AbstractF18DeoxyGlucoseKinetics.q2( ...                
                this.dtaNyquist.specificActivity, this.k1, this.itsA, this.itsB, this.k4, this.tscNyquist.times);
        end
        function q3   = itsQ3(this)
            q3 = mlkinetics.AbstractF18DeoxyGlucoseKinetics.q3( ...                
                this.dtaNyquist.specificActivity, this.k1, this.itsA, this.itsB, this.k3, this.tscNyquist.times);
        end
        function qpet = itsQpet(this)
            qpetCell = this.estimateDataFast( ...
                this.fu, this.k1 ,this.k2, this.k3, this.k4, this.u0, this.v1);
            qpet = qpetCell{1};
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            this = this.runMcmc(ip.Results.mapParams, 'keysToVerify', {'fu' 'k1' 'k2' 'k3' 'k4' 'u0' 'v1'});
        end
        function ed   = estimateDataFast(this, fu, k1, k2, k3, k4, u0, v1)
            %% ESTIMATEDATAFAST is used by AbstractBayesianStrategy.theSolver.
            
            tNyquist = this.tscNyquist.times;
            qNyquist = mlkinetics.AbstractF18DeoxyGlucoseKinetics.qpet( ...
                this.dtaNyquist.specificActivity, fu, k1, k2, k3, k4, tNyquist, v1);
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
            addParameter(ip, 'fileprefix', this.fqfileprefix, @ischar);
            addParameter(ip, 'Sheet', 1, @isnumeric);
            addParameter(ip, 'Range', 'A3:U3', @ischar);
            addParameter(ip, 'writeHeader', true, @islogical);
            parse(ip, varargin{:});            
            if (isempty(this.summary))
                this = this.load([ip.Results.fileprefix this.filesuffix]);
            end
            summary = this.summary;
            
            if (ip.Results.writeHeader)
                H = cell2table({'subject', 'visit', 'ROI', 'plasma glu (mg/dL)', 'Hct', 'WB glu (mmol/L)', 'CBV (mL/100g)', ...
                     'k1 (1/s)', 'std(k1)', 'k2 (1/s)', 'std(k2)', 'k3 (1/s)', 'std(k3)', 'k4 (1/s)', 'std(k4)', ...
                     't_offset (s)', 'std(t_offset)', 'chi', 'Kd', 'CMR', 'free', '', 'CTXglu', 'CMRglu', 'free glu'});
                writetable(H, [ip.Results.fileprefix '.xlsx'], ...
                    'Sheet', ip.Results.Sheet, 'Range', 'A2:Y2', 'WriteVariableNames', false);
            end
            
            subjid = this.sessionData.sessionFolder;
            sp = summary.stdParams;
            v = this.sessionData.vnumber;
            roi = this.translateYeo7(this.sessionData.parcellation);
            T = cell2table({subjid, v, roi, 90, summary.hct, [], 100*this.v1, ...
                this.k1, sp(2), this.k2, sp(3), this.k3, sp(4), this.k4, sp(5), this.u0, sp(6), ...
                summary.chi, summary.Kd, summary.CMR, summary.free});
            writetable(T, [ip.Results.fileprefix '.xlsx'], ...
                'Sheet', ip.Results.Sheet, 'Range', ip.Results.Range, 'WriteVariableNames', false);
        end
    end
    
    %% PROTECTED
    
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
                     mlkinetics.AbstractF18DeoxyGlucoseKinetics.qpet( ...
                         Aa, argsv{1}, argsv{2}, argsv{3}, argsv{4}, this.times{1}, argsv{5}, argsv{6}));
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

