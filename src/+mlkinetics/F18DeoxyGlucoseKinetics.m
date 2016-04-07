classdef F18DeoxyGlucoseKinetics < mlkinetics.AbstractKinetics & mlkinetics.F18
	%% F18DEOXYGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 21-Jan-2016 16:55:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
        fu = 1 % FUDGE
                                   % Joanne Markham used the notation K_1 = V_B*k_{21}, rate from compartment 1 to 2.
        k1 = 3.9461/60 %(0.102  + 0.054)/2/60 % Mean of grey, white values from Huang Am J Physiol 1980, but in s^{-1}.
        k2 = 0.30926/60 %(0.130  + 0.109)/2/60
        k3 = 0.18617/60 %(0.062  + 0.045)/2/60
        k4 = 0.013817/60 %(0.0068 + 0.0058)/2/60
        u0 = 4.038 % for tscCounts
        v1 = 0.0305
        
        sk1 = 0.028/60
        sk2 = 0.066/60
        sk3 = 0.019/60
        sk4 = 0.0017/60
        
        sessionData
        Ca     
        xLabel = 'times/s'
        yLabel = 'activity'
        notes
    end
    
    properties (Dependent)
        baseTitle
        detailedTitle
        mapParams 
        parameters
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            if (isempty(this.sessionData))
                bt = sprintf('%s %s', class(this), pwd);
                return
            end
            bt = sprintf('%s %s', class(this), this.sessionData.sessionFolder);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nfu %g, k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g\n%S', ...
                         this.baseTitle, ...
                         this.fu, this.k1, this.k2, this.k3, this.k4, this.u0, this.v1, this.notes);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            N = 50;
            m('fu') = struct('fixed', 1, 'min', eps,                          'mean', this.fu, 'max',           100);  
            m('k1') = struct('fixed', 0, 'min', max(this.k1 - N*this.sk1, 0), 'mean', this.k1, 'max', this.k1 + N*this.sk1);
            m('k2') = struct('fixed', 0, 'min', max(this.k2 - N*this.sk2, 0), 'mean', this.k2, 'max', this.k2 + N*this.sk2);
            m('k3') = struct('fixed', 0, 'min', max(this.k3 - N*this.sk3, 0), 'mean', this.k3, 'max', this.k3 + N*this.sk3);
            m('k4') = struct('fixed', 0, 'min', max(this.k4 - N*this.sk4, 0), 'mean', this.k4, 'max', this.k4 + N*this.sk4);
            m('u0') = struct('fixed', 1, 'min', 0,                            'mean', this.u0, 'max',           100);  
            m('v1') = struct('fixed', 1, 'min', 0,                            'mean', this.v1, 'max',           0.1);  
        end
        function p  = get.parameters(this)            
            p   = [this.finalParams('fu'), this.finalParams('k1'), this.finalParams('k2'), ...
                   this.finalParams('k3'), this.finalParams('k4'), this.finalParams('u0'), this.finalParams('v1')]; 
        end
    end
    
    methods (Static)
        function [this,kmin,k1k3overk2k3] = runYi(Ca, t, qpet, notes)
            assert(isnumeric(Ca));
            assert(isnumeric(t));
            assert(isnumeric(qpet));
            assert(length(Ca) == length(t) && length(t) == length(qpet));
            
            this           = mlkinetics.F18DeoxyGlucoseKinetics({t}, {qpet});
            Ca(Ca < 0)     = 0;
            this.Ca        = Ca;
            this.notes     = notes;
            this.showPlots = true;
            this           = this.estimateParameters;
            this.plotTimeSamples
            
            kmin         = 60*[this.k1 this.k2 this.k3 this.k4];
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            fprintf('frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
        end
        function [this,kmin,k1k3overk2k3] = runPowers(sessDat)
            import mlpet.*;
            cd(sessDat.sessionPath);
            sessDat.fslmerge_t;
            dta  = DTA.loadSessionData(sessDat);
            tsc  = TSC.import(sessDat.tsc_fqfn);
            
            this           = mlkinetics.F18DeoxyGlucoseKinetics({ tsc.times }, { tsc.becquerels });
            this.Ca        = pchip(dta.times, dta.becquerels, tsc.times);
            this.showPlots = true;
            this           = this.estimateParameters;
            this.plotTimeSamples;
            
            kmin         = 60*[this.k1 this.k2 this.k3 this.k4];
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            fprintf('frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
        end
        function [this,kmin,k1k3overk2k3] = runSession(sessDat)
            import mlkinetics.*;
            switch (class(sessDat))
                case 'mlpowers.SessionData'
                    [this,kmin,k1k3overk2k3] = F18DeoxyGlucoseKinetics.runPowers(sessDat);
                otherwise
                    error('mlkinetics:unsupportedSwitchCase', ...
                         'class(F18DeoxyGlucoseKinetics.runSession.sessDat)->%s', class(sessDat));
            end
        end
        function [output,toct0,toct1] = looper(tag)
            studyDat = mlpipeline.StudyDataSingletons.instance(tag);
            assert(studyDat.isLocalhost); % studyData must query for machine identity before returning subjectsDir and other filesystem information.     
            
            t0 = tic;
            studyDat.diaryOn;
            sessPths = studyDat.sessionPaths;
            visits   = studyDat.visits;
            regions  = studyDat.regions;            
            output   = cell(length(sessPths), length(visits), length(regions));
            
            for se = 1:length(sessPths)
                for vi = 1:length(visits)
                    for re = 1:length(regions)
                        try
                            t1 = tic;
                            fprintf('%s:  is working with session %s visit %s region %s\n', mfilename, sessPths{se}, visits{vi}, regions{re});
                            fdgk = mlkinetics.F18DeoxyGlucoseKinetics.runSession( ...
                                studyDat.sessionData('sessionPath', sessPths{se}, 'vnumber', vi, 'rnumber', re));
                            output{se,vi,re} = fdgk;
                            toct1 = toc(t1);
                            fprintf('Elapsed time:  %g seconds\n\n\n\n', toct1);
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
            
            studyDat.saveWorkspace;
            studyDat.diaryOff;
            toct0 = toc(t0);         
        end
        function [output,toct0,toct1] = loopSubjectsLocally(tag)
        end
        function [output,toct0,toct1] = loopSessionsLocally(tag)
        end
        function [output,toct0,toct1] = loopRegionsLocally(tag)
        end
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
        function q      = q2(Ca, k1, a, b, k4, t)
            scale = k1/(b - a);
            q = scale * conv((k4 - a)*exp(-a*t) + (b - k4)*exp(-b*t), Ca);
            q = q(1:length(t));
        end
        function q      = q3(Ca, k1, a, b, k3, t)
            scale = k3*k1/(b - a);
            q = scale * conv(exp(-a*t) - exp(-b*t), Ca);
            q = q(1:length(t));
        end
        function q      = qpet(Ca, fu, k1, k2, k3, k4, t, u0, v1)
            import mlkinetics.*;
            a = F18DeoxyGlucoseKinetics.a(k2, k3, k4);
            b = F18DeoxyGlucoseKinetics.b(k2, k3, k4);
            q = fu*F18DeoxyGlucoseKinetics.q2(Ca, k1, a, b, k4, t) + ...
                fu*F18DeoxyGlucoseKinetics.q3(Ca, k1, a, b, k3, t) + ...
                v1*Ca;
            q = F18DeoxyGlucoseKinetics.slide(q, t, u0); 
        end
        function this   = simulateMcmc(Ca, fu, k1, k2, k3, k4, t, u0, v1, mapParams)
            import mlkinetics.*;
            qpet = F18DeoxyGlucoseKinetics.qpet(Ca, fu, k1, k2, k3, k4, t, u0, v1);
            this = F18DeoxyGlucoseKinetics({t}, {qpet});
            this.Ca = Ca;
            this.showAnnealing = true;
            this.showBeta = true;
            this.showPlots = true;
            this = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plotTimeSamples;
        end    
    end
    
	methods
 		function this = F18DeoxyGlucoseKinetics(varargin)
 			%% F18DEOXYGLUCOSEKINETICS
 			%  Usage:  this = F18DeoxyGlucoseKinetics() 			
 			
 			this = this@mlkinetics.AbstractKinetics(varargin{:});
            this.expectedBestFitParams_ = ...
                [this.fu this.k1 this.k2 this.k3 this.k4 this.u0 this.v1]';
        end
        
        function this = simulateItsMcmc(this)
            this = mlkinetics.F18DeoxyGlucoseKinetics.simulateMcmc( ...
                   this.Ca, this.fu, this.k1, this.k2, this.k3, this.k4, this.times{1}, this.u0, this.v1, this.mapParams);
        end
        function a    = itsA(this)
            a = mlkinetics.F18DeoxyGlucoseKinetics.a(this.k2, this.k3, this.k4);
        end
        function b    = itsB(this)
            b = mlkinetics.F18DeoxyGlucoseKinetics.b(this.k2, this.k3, this.k4);
        end
        function q2   = itsQ2(this)
            q2 = mlkinetics.F18DeoxyGlucoseKinetics.q2(this.Ca, this.k1, this.itsA, this.itsB, this.k4, this.times{1});
        end
        function q3   = itsQ3(this)
            q3 = mlkinetics.F18DeoxyGlucoseKinetics.q3(this.Ca, this.k1, this.itsA, this.itsB, this.k3, this.times{1});
        end
        function qpet = itsQpet(this)
            qpet = mlkinetics.F18DeoxyGlucoseKinetics.qpet( ...
                this.Ca, this.fu, this.k1, this.k2, this.k3, this.k4, this.times{1}, this.u0, this.v1);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            this = this.runMcmc(ip.Results.mapParams, {'fu' 'k1' 'k2' 'k3' 'k4' 'u0' 'v1'});
        end
        function ed   = estimateDataFast(this, fu, k1, k2, k3, k4, u0, v1)
            ed{1} = this.qpet(this.Ca, fu, k1, k2, k3, k4, this.times{1}, u0, v1);
        end
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (ps(theParams.paramsIndices('k4')) > ps(theParams.paramsIndices('k3')))
                tmp                               = ps(theParams.paramsIndices('k3'));
                ps(theParams.paramsIndices('k3')) = ps(theParams.paramsIndices('k4'));
                ps(theParams.paramsIndices('k4')) = tmp;
            end
%             if (ps(theParams.paramsIndices('k2')) > ps(theParams.paramsIndices('k1')))
%                 tmp                               = ps(theParams.paramsIndices('k1'));
%                 ps(theParams.paramsIndices('k1')) = ps(theParams.paramsIndices('k2'));
%                 ps(theParams.paramsIndices('k2')) = tmp;
%             end
        end
        
        function plot(this, varargin)
            figure;
            max_Ca    = max(this.Ca);
            max_data1 = max(this.dependentData{1}, this.itsQpet);
            plot(this.times{1}, this.Ca              /max_Ca, ':o',  ...
                 this.times{1}, this.itsQpet         /max_data1, ...
                 this.times{1}, this.dependentData{1}/max_data1, ':s', varargin{:});
            legend('data Ca', 'Bayesian qpet', 'data qpet');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s; rescaled by %g, %g', this.yLabel,  max_Ca, max_data1));
        end
        function plotTimeSamples(this, varargin)
            figure;
            max_Ca    = max(this.Ca);
            max_data1 = max(max(this.dependentData{1}), max(this.itsQpet));
            plot(1:length(this.times{1}), this.Ca              /max_Ca, ':o',  ...
                 1:length(this.times{1}), this.itsQpet         /max_data1, ...
                 1:length(this.times{1}), this.dependentData{1}/max_data1, ':s', varargin{:});
            legend('data Ca', 'Bayesian qpet', 'data qpet');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel('time sample index (cardinal)');
            ylabel(sprintf('%s; rescaled by %g, %g', this.yLabel,  max_Ca, max_data1));
        end
        function plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
                case 'k1'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.k2 this.k3 this.k4 this.u0 this.v1}; 
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
 	end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlkinetics.F18DeoxyGlucoseKinetics')));
            assert(iscell(args));
            assert(isnumeric(vars));
            figure
            hold on
            plot(0:length(this.Ca)-1, this.Ca, 'o')
            for v = 1:length(args)
                argsv = args{v};
                plot(0:length(this.Ca)-1, ...
                     mlkinetics.F18DeoxyGlucoseKinetics.qpet( ...
                         this.Ca, argsv{1}, argsv{2}, argsv{3}, argsv{4}, this.times{1}, argsv{5}, argsv{6}));
            end
            plot(0:length(this.Ca)-1, this.dependentData{1}, 'LineWidth', 2);
            title(sprintf('k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(['idaif' ...
                    cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false) ...
                    'WB']);
            xlabel('time sampling index');
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

