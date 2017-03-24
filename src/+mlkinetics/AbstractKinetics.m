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
    end

	methods (Static)
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
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
            %% SUMSQUAREDERRORS returns the sum-of-squared-errors summed over the cells of this.dependentData and 
            %  corresponding this.estimateDataFast.  Compared to AbstractMcmcStrategy.sumSquaredErrors, this 
            %  method override weights the sum-of-squared-errors with Jeffrey's prior according to this.independentData.
            %  See also:  mlbayesian.AbstractMcmcStrategy.sumSquaredErrors, 
            %             mlkinetics.AbstractKinetics.JeffreysPrior.
            
            assert(~isempty(this.jeffreysPrior));
            p   = num2cell(p);
            sse = 0;
            edf = this.estimateDataFast(p{:});
            for iidx = 1:length(this.dependentData)
                sse = sse + ...
                      sum(abs(this.dependentData{iidx} - edf{iidx}).^2.*this.jeffreysPrior{iidx})./sum(abs(this.dependentData{iidx}).^2);
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
                p{iidx} = 1./(t*log(t(end)/t(1)));
            end
        end
 	end 
    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

