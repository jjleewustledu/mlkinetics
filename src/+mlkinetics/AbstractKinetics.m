classdef AbstractKinetics < mlbayesian.AbstractMcmcStrategy
	%% ABSTRACTKINETICS  

	%  $Revision$
 	%  was created 08-Feb-2016 20:02:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2016, 2017 John Joowon Lee.
 	
    
    properties
        jeffreysPrior
        mask % for scanner data
        summary
    end
    
    properties (Dependent)        
        baseTitle
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            if (isempty(this.sessionData))
                bt = sprintf('%s %s', class(this), pwd);
                return
            end
            bt = sprintf('%s %s', class(this), this.sessionData.sessionFolder);
        end
    end

	methods (Static)
        function [t,interp1,interp2, Dt] = interpolateAll(t1, A1, t2, A2)
            %% INTERPOLATEALL interpolates variably sampled {t1 conc1} and {t2 conc2} to {t interp1} and {t interp2}
            %  so that t satisfies Nyquist sampling.  [t1 conc1] is dta and [t2 conc2] is tsc.
            %  As the FDG dta sampled from the radial artery typically lags the tsc, interpolateAll
            %  shifts dta to earlier times to preserve causality.  Dt = t(inflow(tsc)) - t(inflow(dta)) < 0.
            %  Slides dta to inertial-frame of tsc.
            
            dt   = 1; % min([timeDifferences(t1) timeDifferences(t2)]) / 2;
            tInf = min([t1 t2]);
            tSup = max([t1 t2]);
            
            import mlkinetics.*;
            Dt            = AbstractKinetics.lagRadialArtery(t1, A1, t2, A2); % > 0            
            [t1,A1,t2,A2] = AbstractKinetics.interpolateBoundaries(t1, A1, t2, A2);                     
            t             = tInf:dt:tSup;
            interp1       = AbstractKinetics.slide(pchip(t1,A1,t), t, -Dt); 
            interp2       = pchip(t2,A2,t);            

            function timeDiffs = timeDifferences(times)
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
 		function this = AbstractKinetics(varargin)
 			%% ABSTRACTKINETICS
 			%  Usage:  this = AbstractKinetics()
 			
 			this = this@mlbayesian.AbstractMcmcStrategy(varargin{:});  
        end        
        function sse  = sumSquaredErrors(this, p)
            %% SUMSQUAREDERRORS returns the sum-of-square residuals for all cells of this.dependentData and 
            %  corresponding this.estimateDataFast.  Compared to AbstractMcmcStrategy.sumSquaredErrors, this 
            %  overriding implementation weights of the log-likelihood with Jeffrey's prior according to this.independentData.
            %  See also:  mlbayesian.AbstractMcmcStrategy.sumSquaredErrors, 
            %             mlkinetics.AbstractKinetics.jeffreysPrior.
            
            assert(~isempty(this.jeffreysPrior));
            p   = num2cell(p);
            sse = 0;
            edf = this.estimateDataFast(p{:});
            for iidx = 1:length(this.dependentData)
                sse = sse + ...
                      sum( (this.dependentData{iidx} - edf{iidx}).^2.*this.jeffreysPrior{iidx}./ ...
                            this.dependentData{iidx} );
            end
            if (sse < eps)
                sse = sse + (1 + rand(1))*eps; 
            end
        end
        function rsn  = translateYeo7(~, roi)
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
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function p = buildJeffreysPrior(this)
            %% JEFFREYSPRIOR
            %  Cf. Gregory, Bayesian Logical Data Analysis for the Physical Sciences, sec. 3.7.1.
            
            p = cell(this.independentData);
            for iidx = 1:length(p)
                t = this.independentData{iidx};
                for it = 1:length(t)
                    if (abs(t(it)) < eps)
                        t(it) = min(t(t > eps));
                    end
                end
                p{iidx} = 1./t*log(t(end)/t(1));
            end
        end
 	end 
    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

