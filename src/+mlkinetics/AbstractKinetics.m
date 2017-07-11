classdef AbstractKinetics < mlbayesian.AbstractMcmcStrategy
	%% ABSTRACTKINETICS  

	%  $Revision$
 	%  was created 08-Feb-2016 20:02:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2016, 2017 John Joowon Lee.
 	
    
    properties      
        arterialNyquist
        mask % for scanner data  
        scannerNyquist
        summary
    end
    
    properties (Dependent)
        baseTitle
    end    
    
    methods (Abstract)
        this = prepareArterialData(this)
        this = prepareScannerData(this)        
    end
    
	methods (Static)
        function [t,interp1,interp2, Dt] = interpolateAll(t1, A1, t2, A2)
            %% INTERPOLATEALL interpolates variably sampled {t1 conc1} and {t2 conc2} to {t interp1} and {t interp2}
            %  so that t satisfies Nyquist sampling.  [t1 conc1] is dta and [t2 conc2] is tsc.
            %  As the FDG dta sampled from the radial artery typically lags the tsc, interpolateAll
            %  shifts dta to earlier times to preserve causality.  Dt = t(inflow(tsc)) - t(inflow(dta)) < 0.
            %  Slides dta to inertial-frame of tsc.
            
            %t1   = ensureRowVector(t1);
            %A1   = ensureColVector(A1);
            %t2   = ensureRowVector(t2);
            %A2   = ensureColVector(A2);
            dt   = 1; % min([timeDifferences(t1) timeDifferences(t2)]) / 2;
            tInf = min([t1 t2]);
            tSup = max([t1 t2]);
            
            import mlkinetics.*;
            Dt            = AbstractKinetics.lagRadialArtery(t1, A1, t2, A2); % > 0            
            [t1,A1,t2,A2] = AbstractKinetics.interpolateBoundaries(t1, A1, t2, A2);                     
            t             = tInf:dt:tSup;
            interp1       = AbstractKinetics.slide(pchip(t1,A1,t), t, -Dt); 
            interp2       = pchip(t2,A2,t);            

            function timeDiffs = timeDifferences(times) %#ok<DEFNU>
                timeDiffs = times(2:end) - times(1:end-1);
            end
        end
        function [t1,A1,t2,A2] = interpolateBoundaries(t1, A1, t2, A2)
            %% INTERPOLATEBOUNDARIES prepends or appends time and concentration datapoints to manage boundaries
            %  when invoking pchip.  The first or last times and concentrations are repeated as needed to fill
            %  boundary values.
            
            if (t1(1) < t2(1))
                t2    = [t1(1)    t2];
                A2 = [A2(1) A2];
            end
            if (t1(1) > t2(1))                
                t1    = [t2(1)    t1];
                A1 = [A1(1) A1];
            end
            if (t1(end) < t2(end))
                t1 =    [t1    t2(end)];
                A1 = [A1 A1(end)];
            end
            if (t1(end) > t2(end))
                t2 =    [t2    t1(end)];
                A2 = [A2 A2(end)];
            end
        end
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
        function Dt   = lagRadialArtery(tdta, dta, ttsc, tsc)
            [~,idx_max_dta]   = max(dta);
            dtaFront          = dta(1:idx_max_dta);
            [~,idx_start_dta] = max(dtaFront > 0.01*max(dtaFront));
            [~,idx_start_tsc] = max(tsc      > 0.01*max(tsc));
            Dt = tdta(idx_start_dta) - ttsc(idx_start_tsc);
        end
        function f    = mLmin100g_to_invs(f)
            f = mlpet.AutoradiographyBuilder.BRAIN_DENSITY * f / 6000;
        end
    end
    
    methods 
        
        %% GET
        
        function g    = get.baseTitle(this)
            if (isempty(this.sessionData))
                g = sprintf('%s in %s', class(this), pwd);
                return
            end
            g = sprintf('%s in %s', class(this), this.sessionData.sessionFolder);
        end
        
        %%
        
        function tf   = checkConstructKineticsPassed(this)
            error('mlkinetics:notImplemented', 'AbstractKinetics.checkConstructKineticsPassed');
        end
        function [this,lg] = doBayes(this)
            tic            
            this = this.estimateParameters;
            this.plotAll;
            saveFigures(sprintf('fig_%s', this.fileprefix));            
            this = this.updateSummary;
            this.save;
            this.writetable;
            lg = this.logging;
            lg.save('w');   
            fprintf('mlkinetics.AbstractKinetics.doBayes:');
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
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            this = this.runMcmc(ip.Results.mapParams, 'keysToVerify', this.keysParams_);
        end
        function lg   = logging(this) %#ok<STOUT,MANU>
        end
        function this = updateSummary(this)
        end
        function        writetable(this, varargin) %#ok<INUSD>
        end
        
 		function this = AbstractKinetics(varargin)
 			%% ABSTRACTKINETICS
 			%  Usage:  this = AbstractKinetics()
 			
 			this = this@mlbayesian.AbstractMcmcStrategy(varargin{:});  
        end   
    end    
    
    %% PROTECTED
    
    properties (Access = 'protected')
        keysParams_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

