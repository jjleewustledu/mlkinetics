classdef F18DeoxyGlucoseLaif < mlkinetics.AbstractKinetics
	%% F18DEOXYGLUCOSELAIF  

	%  $Revision$
 	%  was created 21-Jan-2016 16:55:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties
        c0 = 44679
        ca = 9.5
        cb = 0.58
        ce = 0.0037
        cg = 0.69
        
        fu = 7180 % fudge
        k1 = (0.102  + 0.054)/2/60 % Joanne Markham used the notation K_1 = V_B*k_{21}, rate from compartment 1 to 2.
        k2 = (0.130  + 0.109)/2/60 % Mean of grey, white values from Huang Am J Physiol 1980, but in s^{-1}.
        k3 = (0.062  + 0.045)/2/60
        k4 = (0.0068 + 0.0058)/2/60
        
        t0 = 0 % for Cart
        u0 = 0 % for tsc
        v1 = 0.04   
         
        xLabel = 'times/s'
        yLabel = 'activity'
        notes  = ''
    end
    
    properties (Constant)        
        sk1 = 0.028/60 % Stddev of grey, white values from Huang Am J Physiol 1980, but in s^{-1}.
        sk2 = 0.066/60
        sk3 = 0.019/60
        sk4 = 0.0017/60        
    end
    
    properties (Dependent)
        detailedTitle
        mapParams 
        parameters
    end
    
    methods %% GET
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nc0 %g, ca %g, cb %g, ce %g, cg %g\nfu %g, k1 %g, k2 %g, k3 %g, k4 %g\nt0 %g, u0 %g, v1 %g\n%s', ...
                         this.baseTitle, ...
                         this.c0, this.ca, this.cb, this.ce, this.cg, ...
                         this.fu, this.k1, this.k2, this.k3, this.k4, ...
                         this.t0, this.u0, this.v1, this.notes);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            N = 10;
            m('c0') = struct('fixed', 0, 'min', this.c0/N,                    'mean', this.c0, 'max', this.c0*N + eps); 
            m('ca') = struct('fixed', 0, 'min', this.ca/N,                    'mean', this.ca, 'max', this.ca*N + eps);  
            m('cb') = struct('fixed', 0, 'min', this.cb/N,                    'mean', this.cb, 'max', this.cb*N + eps);  
            m('ce') = struct('fixed', 0, 'min', this.ce/N,                    'mean', this.ce, 'max', this.ce*N + eps);  
            m('cg') = struct('fixed', 0, 'min', this.cg/N,                    'mean', this.cg, 'max', this.cg*N + eps);  
            
            m('fu') = struct('fixed', 0, 'min', this.fu/N,                    'mean', this.fu, 'max',           N*this.fu);
            m('k1') = struct('fixed', 1, 'min', max(this.k1 - N*this.sk1, 0), 'mean', this.k1, 'max', this.k1 + N*this.sk1);
            m('k2') = struct('fixed', 1, 'min', max(this.k2 - N*this.sk2, 0), 'mean', this.k2, 'max', this.k2 + N*this.sk2);
            m('k3') = struct('fixed', 1, 'min', max(this.k3 - N*this.sk3, 0), 'mean', this.k3, 'max', this.k3 + N*this.sk3);
            m('k4') = struct('fixed', 1, 'min', max(this.k4 - N*this.sk4, 0), 'mean', this.k4, 'max', this.k4 + N*this.sk4);
            
            m('t0') = struct('fixed', 1, 'min', 0,                            'mean', this.t0, 'max',          10*this.t0 + eps);  
            m('u0') = struct('fixed', 1, 'min', 0,                            'mean', this.u0, 'max',          10*this.u0 + eps);  
            m('v1') = struct('fixed', 1, 'min', 0,                            'mean', this.v1, 'max',           0.1);  
        end
        function p  = get.parameters(this)
            p   = [this.finalParams('c0'), ...
                   this.finalParams('ca'), this.finalParams('cb'), this.finalParams('ce'), this.finalParams('cg'), ...
                   this.finalParams('fu'), ...
                   this.finalParams('k1'), this.finalParams('k2'), this.finalParams('k3'), this.finalParams('k4'), ...
                   this.finalParams('t0'), this.finalParams('u0'), this.finalParams('v1')]; 
        end
    end
    
    methods (Static)
        function [kmin,k1k3overk2k3,fdgl] = run(t, qpet)
            assert(isnumeric(t));
            assert(isnumeric(qpet));            
            assert(length(t) == length(qpet));
            t0             = tic;
            
            fdgl           = mlkinetics.F18DeoxyGlucoseLaif({t}, {qpet});
            fdgl.showAnnealing = true;
            fdgl.showBeta  = true;
            fdgl.showPlots = true;
            fdgl.notes     = '';
            fdgl           = fdgl.estimateParameters;
            fdgl.plotTimeSamples
            
            kmin         = 60*[fdgl.k1 fdgl.k2 fdgl.k3 fdgl.k4];
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n[k_1 ... k_4] / min^{-1} -> %s\n',          mat2str(kmin));
            fprintf('frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));            
            fprintf('F18DeoxyGlucoseLaif.run elapsed time -> %g', toc(t0));
        end
        function [output,toct0,toct1] = loopRegionsLocally(tag)
            studyDat = mlpipeline.StudyDataSingleton.instance(tag);   
            
            t0 = tic;
            studyDat.diaryOn;
            sessPths = studyDat.sessionPaths;
            visits   = studyDat.visits;
            regions  = studyDat.regions;            
            output   = cell(length(sessPths), length(visits), length(regions));
            
            for se = 1:1 %length(sessPths)
                for vi = 1:1 %length(visits)
                    for re = 1:1 %length(regions)
                        try
                            t1 = tic;
                            fprintf('%s:  is working with session %s visit %s region %s\n', mfilename, sessPths{d}, visits{vi}, regions{re});
                            rm = mlkinetics.RegionalMeasurements();
                            [v,rm] = rm.vFrac;
                            k      = rm.kinetics; 
                            k      = k.parameters;
                            output{se,vi,re} = struct('v', v, 'kinetics', k);
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
        function cart   = Cart(c0, ca, cb, ce, cg, t, t0)
            import mlperfusion.LaifTerms.*;
            cart = bolusFlowTerm(ca, cb, t0, t) + bolusSteadyStateTerm(ce, cg, t0, t);
            cart = c0 * cart;
        end
        function q      = q2(Cart, k1, a, b, k4, t, v1)
            scale = k1*v1/(b - a);
            q = scale * conv((k4 - a)*exp(-a*t) + (b - k4)*exp(-b*t), Cart);
            q = q(1:length(t));
        end
        function q      = q3(Cart, k1, a, b, k3, t, v1)
            scale = k3*k1*v1/(b - a);
            q = scale * conv(exp(-a*t) - exp(-b*t), Cart);
            q = q(1:length(t));
        end
        function q      = qpet(Cart, fu, k1, k2, k3, k4, t, u0, v1)
            import mlkinetics.*;
            a = F18DeoxyGlucoseLaif.a(k2, k3, k4);
            b = F18DeoxyGlucoseLaif.b(k2, k3, k4);
            q = v1 * Cart + ...
                fu * F18DeoxyGlucoseLaif.q2(Cart, k1, a, b, k4, t, v1) + ...
                fu * F18DeoxyGlucoseLaif.q3(Cart, k1, a, b, k3, t, v1);
            %q = F18DeoxyGlucoseLaif.slide(q, t, u0);
        end
        function this   = simulateMcmc(c0, ca, cb, ce, cg, fu, k1, k2, k3, k4, t, t0, u0, v1, mapParams)
            import mlkinetics.*;
            Cart = F18DeoxyGlucoseLaif.Cart(c0, ca, cb, ce, cg, t, t0);
            qpet = F18DeoxyGlucoseLaif.qpet(Cart, fu, k1, k2, k3, k4, t, t0, u0, v1);
            this = F18DeoxyGlucoseLaif({t}, {qpet});
            this.showAnnealing = true;
            this.showBeta = true;
            this.showPlots = true;
            this = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plotTimeSamples;
        end    
    end
    
	methods
 		function this = F18DeoxyGlucoseLaif(varargin)
 			%% F18DEOXYGLUCOSELAIF
 			%  Usage:  this = F18DeoxyGlucoseLaif() 			
 			
 			this = this@mlkinetics.AbstractKinetics(varargin{:});
            this.expectedBestFitParams_ = ...
                [this.c0 this.ca this.cb this.ce this.cg ...
                this.fu this.k1 this.k2 this.k3 this.k4 ...
                this.t0 this.u0 this.v1]';
        end
        
        function this = simulateItsMcmc(this)
            this = mlkinetics.F18DeoxyGlucoseLaif.simulateMcmc( ...
                   this.c0, this.ca, this.cb, this.ce, this.cg, ...
                   this.fu, this.k1, this.k2, this.k3, this.k4, ...
                   this.times{1}, this.t0, this.u0, this.v1, this.mapParams);
        end
        function a    = itsA(this)
            a = mlkinetics.F18DeoxyGlucoseLaif.a(this.k2, this.k3, this.k4);
        end
        function b    = itsB(this)
            b = mlkinetics.F18DeoxyGlucoseLaif.b(this.k2, this.k3, this.k4);
        end
        function ca   = itsCart(this)
            ca = mlkinetics.F18DeoxyGlucoseLaif.Cart(this.c0, this.ca, this.cb, this.ce, this.cg, this.times{1}, this.t0);
        end
        function q2   = itsQ2(this)
            q2 = mlkinetics.F18DeoxyGlucoseLaif.q2(this.itsCart, this.k1, this.itsA, this.itsB, this.k4, this.times{1}, this.v1);
        end
        function q3   = itsQ3(this)
            q3 = mlkinetics.F18DeoxyGlucoseLaif.q3(this.itsCart, this.k1, this.itsA, this.itsB, this.k3, this.times{1}, this.v1);
        end
        function qpet = itsQpet(this)
            qpet = mlkinetics.F18DeoxyGlucoseLaif.qpet( ...
                this.itsCart, this.fu, this.k1, this.k2, this.k3, this.k4, this.times{1}, this.u0, this.v1);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            this = this.runMcmc(ip.Results.mapParams, ...
                'keysToVerify', {'c0' 'ca' 'cb' 'ce' 'cg' 'fu' 'k1' 'k2' 'k3' 'k4' 't0' 'u0' 'v1'});
        end
        function ed   = estimateDataFast(this, c0, ca, cb, ce, cg, fu, k1, k2, k3, k4, t0, u0, v1)
            import mlkinetics.*;
            ed{1} = F18DeoxyGlucoseLaif.qpet( ...
                    F18DeoxyGlucoseLaif.Cart(c0, ca, cb, ce, cg, this.times{1}, t0), ...
                    fu, k1, k2, k3, k4, this.times{1}, u0, v1);
        end
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (ps(theParams.paramsIndices('cb')) > ps(theParams.paramsIndices('cg')))
                tmp                               = ps(theParams.paramsIndices('cg'));
                ps(theParams.paramsIndices('cg')) = ps(theParams.paramsIndices('cb'));
                ps(theParams.paramsIndices('cb')) = tmp;
            end
            if (ps(theParams.paramsIndices('k4')) > ps(theParams.paramsIndices('k3')))
                tmp                               = ps(theParams.paramsIndices('k3'));
                ps(theParams.paramsIndices('k3')) = ps(theParams.paramsIndices('k4'));
                ps(theParams.paramsIndices('k4')) = tmp;
            end
            if (ps(theParams.paramsIndices('k2')) > ps(theParams.paramsIndices('k1')))
                tmp                               = ps(theParams.paramsIndices('k1'));
                ps(theParams.paramsIndices('k1')) = ps(theParams.paramsIndices('k2'));
                ps(theParams.paramsIndices('k2')) = tmp;
            end
        end
        
        function plot(this, varargin)
            figure;
            max_Ca    = max(this.itsCart);
            max_data1 = max(this.dependentData{1}, this.itsQpet);
            plot(this.times{1}, this.itsCart         /max_Ca, ':o',  ...
                 this.times{1}, this.itsQpet         /max_data1, ...
                 this.times{1}, this.dependentData{1}/max_data1, ':s', varargin{:});
            legend('Bayesian Cart', 'Bayesian qpet', 'data qpet');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s; rescaled by %g, %g', this.yLabel,  max_Ca, max_data1));
        end
        function plotTimeSamples(this, varargin)
            figure;
            max_Ca    = max(this.itsCart);
            max_data1 = max(max(this.dependentData{1}), max(this.itsQpet));
            plot(1:length(this.times{1}), this.itsCart         /max_Ca, ':o',  ...
                 1:length(this.times{1}), this.itsQpet         /max_data1, ...
                 1:length(this.times{1}), this.dependentData{1}/max_data1, ':s', varargin{:});
            legend('Bayesian Cart', 'Bayesian qpet', 'data qpet');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel('time sample index (cardinal)');
            ylabel(sprintf('%s; rescaled by %g, %g', this.yLabel,  max_Ca, max_data1));
        end
        function plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
                case 'c0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'ca'
                    for v = 1:length(vars)
                        args{v} = { this.c0 vars(v) this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'cb'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca vars(v) this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1};  
                    end
                case 'ce'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb vars(v) this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'cg'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce vars(v) this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'fu'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg vars(v) this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'k1'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu vars(v) this.k2 this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'k2'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 vars(v) this.k3 this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'k3'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 vars(v) this.k4 this.t0 this.u0 this.v1}; 
                    end
                case 'k4'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 vars(v) this.t0 this.u0 this.v1};  
                    end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 vars(v) this.u0 this.v1}; 
                    end
                case 'u0'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 vars(v) this.v1}; 
                    end
                case 'v1'
                    for v = 1:length(vars)
                        args{v} = { this.c0 this.ca this.cb this.ce this.cg this.fu this.k1 this.k2 this.k3 this.k4 this.t0 this.u0 vars(v)}; 
                    end
            end
            this.plotParArgs(par, args, vars);
        end
 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

