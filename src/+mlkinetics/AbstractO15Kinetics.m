classdef AbstractO15Kinetics < mlkinetics.AbstractKinetics
	%% ABSTRACTO15KINETICS  
    %  uses m = 1 - exp(-PS/f) 

	%  $Revision$
 	%  was created 05-Jul-2017 20:04:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    properties (Constant)
        BRAIN_DENSITY         = 1.05        % assumed mean brain density, g/mL     
        DECAY_CONSTANT_OF_15O = 0.005670305 % for speed on heap        
        LAMBDA                = 0.95        % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        RBC_FACTOR            = 0.766       % per Tom Videen, metproc.inc, line 193
    end
    
	properties 	
        
        % parameters to estimate
        
        aifAmp
        a
        b
        p
        t01
        t02
        weight1
        S
        k
        t0
        kHand
        t0Hand
        kCircle
        t0Circle
        A1
        A2
        f
        
        aifByDevice % logical
        kernelBestFile % string
        kernelRange % numeric
        psModel % logical
        xLabel = 'time / s'
        yLabel = 'specific activity / (Bq/mL)'
        region
        summary
    end
    
    properties (Dependent)
        aif
        hct
        kernelSamplingDevice
        laif
        scanner
    end

    methods (Static)
        function mdl  = model( ...
                aifByDevice, aifAmp, a, b, p, t01, t02, weight1, S, k, t0, ...
                kHand, t0Hand, ...
                kCircle, t0Circle, ...
                A1, A2, f, ...                
                tAif, tScanner, tInterp, krnlDevice)
            import mlkinetics.*;
            mdl{1} = AbstractHoKinetics.modelAifSampled( ...
                aifByDevice, aifAmp, a, b, p, t01, t02, weight1, S, k, t0, tAif,     tInterp, krnlDevice, kHand,   t0Hand); % from laif model
            mdl{2} = AbstractHoKinetics.modelAifCircleWillis( ...
                             aifAmp, a, b, p, t01, t02, weight1, S, k, t0, tScanner, tInterp,             kCircle, t0Circle); % "
            mdl{3} = AbstractHoKinetics.modelScannerRoi(mdl{1}, PS, f, t0, tScanner); % " 
            mdl{4} = AbstractHoKinetics.modelScannerIntegral(A1, A2, f); % Herscovitch quadratic constraint
        end
        function mdl  = modelAifSampled(aifByDevice, varargin)
            % MODELAIFSAMPLED
            % @param  aifByDevice is logical
            % @param  aifByDevice: a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, krnlDevice, kHand, t0Hand
            % @param ~aifByDevice: a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, kHand, t0Hand
            import mlkinetics.*;
            if (aifByDevice)
                mdl = modelAifDeviceSampled(varargin{:});
                return
            end
            mdl = modelAifExpKernel(varargin{:});
        end
        function mdl  = modelAifCircleWillis(aifAmp, a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, kCircle, t0Circle)
            mdl = mlkinetics.AbstractHoKinetics.modelAifExpKernel( ...
                aifAmp, a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, kCircle, t0Circle);
        end
        function mdl  = modelScannerRoi(aifVec, PS, f, t0, t)
            
            assert(t(end) <= 60); % scanner data, t <= 60 s
            
            import mlkinetics.*;
            m    = 1 - exp(-PS/f);
            mdl0 = m*f* conv( ...
                aifVec, ...
                exp(-(m*f/AbstractO15Kinetics.LAMBDA + AbstractO15Kinetics.DECAY_CONSTANT_OF_15O)*t));
            mdl0 = mdl0(1:length(t));
            mdl  = AbstractO15Kinetics.slide(mdl0, t, t0 - t(1));
        end
        function mdl  = modelScannerIntegral(A1, A2, f)
            % Herscovitch quadratic constraint:  a2 I^2 + a1 I - f = 0, I := \int_T dt I(t), T <= 60 s
            mdl = (-A1 + sqrt(A1^2 + 4*A2*f))/(2*A2);
            assert(mdl > 0);
        end
        function args = mapParams2keysArgs(mapParams)
            aifAmp   = mapParams('aifAmp').mean;
            a        = mapParams('a').mean;
            b        = mapParams('b').mean;
            p        = mapParams('p').mean;
            t01      = mapParams('t01').mean;
            t02      = mapParams('t02').mean;
            weight1  = mapParams('weight1').mean;
            S        = mapParams('S').mean;
            k        = mapParams('k').mean;
            t0       = mapParams('t0').mean;
            kHand    = mapParams('kHand').mean;
            t0Hand   = mapParams('t0Hand').mean;
            kCircle  = mapParams('kCircle').mean;
            t0Circle = mapParams('t0Circle').mean;
            A1       = mapParams('A1').mean;
            A2       = mapParams('A2').mean;
            f        = mapParams('f').mean;
            args     = {aifAmp, a, b, p, t01, t02, weight1, S, k, t0, ...
                        kHand, t0Hand, ...
                        kCircle, t0Circle, ...
                        A1, A2, f};
        end
        function this = simulateMcmc(mapParams, keysParams)
            import mlkinetics.*;
            aifByDevice = true;
            keysArgs = AbstractO15Kinetics.mapParams2keysArgs(mapParams);
            t = 0:60;
            tInterp = 0:0.125:60;
            krnlDevice = AbstractO15Kinetics.loadKernels;            
            
            mdl  = AbstractO15Kinetics.model(aifByDevice, keysArgs{:}, t, t, tInterp, krnlDevice);
            this = AbstractO15Kinetics({t t t t}, mdl);
            this.mapParams = mapParams;
            this.keysParams_ = keysParams;
            [this,lg] = this.doItsBayes;
            fprintf('%s\n', char(lg));
        end
    end
    
	methods
        
        %% GET/SET
        
        function this = set.aif(this, s)
            if (isempty(s))
                this = this.prepareAifData;
                return
            end
            assert(isa(s, 'mlpet.IAifData') || isa(s, 'mlpet.IWellData') || isstruct(s));
            this.aif_ = s;
        end
        function g    = get.aif(this)
            g = this.aif_;
        end
        function g    = get.hct(this)
            g = this.sessionData.hct;
        end
        function g    = get.kernelSamplingDevice(this)
            g = this.kernelSamplingDevice_;
        end
        function g    = get.laif(this)
            fp = this.finalParams; %cellfun(@(x) this.finalParams(x), keys);
            g.specificActivity = mlkinetics.AbstractO15Kinetics.modelLaif( ...
                fp('aifAmp'), fp('a'), fp('b'), fp('p'), fp('t01'), fp('t02'), fp('weight1'), fp('S'), fp('k'), fp('t0'), ...
                this.timeInterpolants{end});
            g.times = this.timeInterpolants{end};
        end
        function this = set.scanner(this, s)
            if (isempty(s))
                this = this.prepareScannerData;
                return
            end
            assert(isa(s, 'mlpet.IScannerData') || isstruct(s))
            this.scanner_ = s;
        end
        function g    = get.scanner(this)
            g = this.scanner_;
        end
        
        %%
        
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (ps(theParams.paramsIndices('f'))  > ps(theParams.paramsIndices('PS')))
                tmp                             = ps(theParams.paramsIndices('PS'));
                ps(theParams.paramsIndices('PS')) = ps(theParams.paramsIndices('f'));
                ps(theParams.paramsIndices('f')) = tmp;
            end
            if (ps(theParams.paramsIndices('t01')) > ps(theParams.paramsIndices('t02')))
                tmp                                = ps(theParams.paramsIndices('t01'));
                ps(theParams.paramsIndices('t01')) = ps(theParams.paramsIndices('t02'));
                ps(theParams.paramsIndices('t02')) = tmp;
            end
        end  
        function edf  = estimateDataFast(this)
            import mlkinetics.*;
            edf = AbstractO15Kinetics.model( ...
                this.aifByDevice, this.aifAmp, this.a, this.b, this.p, this.t01, this.t02, this.weight1, this.S, this.k, this.t0, ...
                this.kHand, this.t0Hand, ...
                this.kCircle, this.t0Circle, ...
                this.A1, this.A2, this.f, ... 
                this.aif.times, this.scanner.times, this.timeInterpolants{end}, this.krnlDevice);
        end
        function        plot(this, varargin)
            figure;
            max_aif     = max(       this.aif.specificActivity);
            max_laif    = max(       this.laif.specificActivity);
            max_scanner = max([max(  this.scanner.specificActivity) max(this.itsModel{end-1})]);
            plot(this.aif.times,     this.aif.specificActivity     /max_aif, '-o',  ...
                 this.laif.times,    this.laif.specificActivity    /max_laif, '-s',  ...
                 this.scanner.times, this.scanner.specificActivity /max_scanner, '-d', ...
                 this.times{end},    this.itsModel{end-1}          /max_scanner, varargin{:});
            legend('data CRV', 'Bayesian DCV', 'data TSC', 'Bayesian TSC');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s\nrescaled by %g, %g, %g', this.yLabel,  max_aif, max_laif, max_scanner));
        end
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
            end
            this.plotParArgs(par, args, vars);
        end
        function this = simulateItsMcmc(this)
            this = mlkinetics.AbstractO15Kinetics.simulateMcmc(this.mapParams, this.keysParams_);
        end 
        function sse  = sumSquaredErrors(this, p)
            %% SUMSQUAREDERRORS returns \int_{t \in T} dt for all cells of this.dependentData and 
            %  corresponding this.model{:}.  
            
            p     = num2cell(p);
            sse   = 0;
            mdl   = this.itsModel(p{:});
            intDD = [];
            len   = length(this.dependentData);
            for iidx = 1:len % depen. data are aifSampled; aifCircleWillis; scannerRoi
                intDD = trapz(this.independentData{iidx}, this.dependentData{iidx});
                sse = sse + ...
                        trapz(this.independentData{iidx}, this.dependentData{iidx} - mdl{iidx}).^2 / intDD^2;
            end
            sse   = sse + (intDD - mdl{len+1})^2 / intDD^2; % intDD := \int_{t \in T} dt scannerRoi(t)
            if (sse < 10*eps)
                sse = sse + (1 + rand(1))*10*eps; 
            end
        end
        
 		function this = AbstractO15Kinetics(varargin)
 			%% ABSTRACTO15KINETICS
 			%  Usage:  this = AbstractO15Kinetics()

 			this = this@mlkinetics.AbstractKinetics(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'kernelBestFile', ...
                fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlarbelaez', 'data', 'kernelBest.mat'), ...
                @(x) lexist(x, 'file'));
            addParameter(ip, 'kernelRange', 13:37, @isnumeric);
            addParameter(ip, 'psModel', true, @islogical);
            addParameter(ip, 'aifByDevice', true, @islogical);
            parse(ip, varargin{:});
            
            this.kernelBestFile = ip.Results.kernelBestFile;
            this.kernelRange = ip.Results.kernelRange;
            this.psModel = ip.Results.psModel;
            this.aifByDevice = ip.Results.aifByDevice;
            this = this.loadItsKernels;
            this.keysParams_ = ...
                {'aifAmp' 'a' 'b' 'p' 't01' 't02' 'weight1' 'S' 'k' 't0' 'kHand' 't0Hand' 'kCircle' 't0Circle' 'A1' 'A2' 'f'};
            this.keysArgs_ = this.mapParams2keysArgs(this.mapParams);
 		end
 	end     
    
    %% PROTECTED
    
    properties (Access = protected)
    end
        
    methods (Static, Access = protected)
        function mdl  = modelAifDeviceSampled( ...
                aifAmp, a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, krnlDevice, kHand, t0Hand)
            import mlkinetics.*;
            laif = AbstractO15Kinetics.modelLaif(a, b, p, t01, t02, weight1, S, k, t0, t);
            laifInterp = pchip(t, laif, tInterp);
            mdl = conv(conv(laifInterp, AbstractO15Kinetics.expKernel(kHand, t0Hand, tInterp)), krnlDevice);
            mdl = mdl(1:length(tInterp));
            mdl = aifAmp*pchip(tInterp, mdl, t);
        end
        function mdl  = modelAifExpKernel( ...
                aifAmp, a, b, p, t01, t02, weight1, S, k, t0, t, tInterp, kKrnl, t0Krnl)
            import mlkinetics.*;
            laif = AbstractO15Kinetics.modelLaif(a, b, p, t01, t02, weight1, S, k, t0, t);
            laifInterp = pchip(t, laif, tInterp);
            mdl = conv(laifInterp, AbstractO15Kinetics.expKernel(kKrnl, t0Krnl, tInterp));
            mdl = mdl(1:length(tInterp));
            mdl = aifAmp*pchip(tInterp, mdl, t);
        end
        function krnl = expKernel(k, t0, tInterp)
            krnl = exp(-k*tInterp)*k / (exp(-k*tInterp(1)) - exp(-k*tInterp(end)));
            krnl = mlkinetics.AbstractO15Kinetics.slide(krnl, tInterp, t0 - tInterp(1));
        end
        function mdl  = modelLaif( ...
                aifAmp, a, b, p, t01, t02, weight1, S, k, t0, t)
            mdl = aifAmp*mlbayesian.GeneralizedGammaTerms.gammaStretchSeriesSteady( ...
                a, b, p, t01, a, b, p, t02, weight1, S, k, t0, t);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        aif_
        hct_
        kernelSamplingDevice_
        scanner_
    end
    
    methods (Static, Access = private)
        function krnl = loadKernels
            mat         = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlarbelaez', 'data', 'kernelBest.mat');
            assert(lexist(mat, 'file'));
            load(mat);
            krnl        = zeros(size(kernelBest));
            krnl(13:37) = kernelBest(13:37);
            krnl        = krnl / trapz(0:length(krnl)-1, krnl);
        end
    end
    
    methods (Access = private)
        function this = loadItsKernels(this)
            load(this.kernelBestFile);
            krnl                   = zeros(size(kernelBest));
            krnl(this.kernelRange) = kernelBest(this.kernelRange);
            krnl = krnl / trapz(0:length(krnl)-1, krnl);
            this.kernelSamplingDevice_ = krnl;
            if (~all(krnl == this.loadKernels))
                warning('mlkinetics:internalDataMismatch', 'loadItsKernels is inconsistent with loadKernels');
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

