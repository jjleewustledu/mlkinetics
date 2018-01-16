classdef AbstractKinetics < mlbayesian.AbstractMcmcStrategy
	%% ABSTRACTKINETICS  

	%  $Revision$
 	%  was created 08-Feb-2016 20:02:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2016, 2017 John Joowon Lee.
 	
    
    properties      
        mask % for scanner data  
    end   
    
    properties (Dependent)
        scanData
    end
    
    methods (Abstract)
        this = prepareAifData(this)
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
            dt   = min([timeDifferences(t1) timeDifferences(t2)]) / 8;
            tInf = min([t1 t2]);
            tSup = max([t1 t2]);
            
            import mlkinetics.*;
            Dt            = timeSeriesDt(t1, A1, t2, A2); % > 0            
            [t1,A1,t2,A2] = interpolateBoundaries(t1, A1, t2, A2);                     
            t             = tInf:dt:tSup;
            interp1       = AbstractKinetics.slide(pchip(t1,A1,t), t, -Dt); 
            interp2       = pchip(t2,A2,t);            

            function timeDiffs = timeDifferences(times)
                timeDiffs = times(2:end) - times(1:end-1);
            end
        end
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
        function f    = mLmin100g_to_invs(f)
            f = mlpet.AutoradiographyBuilder.BRAIN_DENSITY * f / 6000;
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.scanData(this)
            g = this.scanData_;
        end
        
        %%
        
        function tf        = checkConstructKineticsPassed(this)
            error('mlkinetics:notImplemented', 'AbstractKinetics.checkConstructKineticsPassed');
        end
        function [this,lg] = doItsBayes(this)
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
        function             writetable(this, varargin) %#ok<INUSD>
        end
        
 		function this = AbstractKinetics(varargin)
 			%% ABSTRACTKINETICS
 			%  Usage:  this = AbstractKinetics()
 			
 			this = this@mlbayesian.AbstractMcmcStrategy(varargin{:});  
        end   
    end    
    
    %% PROTECTED
    
    properties (Access = 'protected')
        scanData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

