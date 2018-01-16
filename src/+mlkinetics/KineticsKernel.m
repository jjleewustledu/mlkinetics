classdef KineticsKernel < mlbayesian.NullKernel
	%% KINETICSKERNEL  

	%  $Revision$
 	%  was created 12-Jan-2018 14:36:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties 		
        aifTimesInterp
        aifSpecificActivityInterp
    end
    
    methods (Static)
        function this = main(varargin)
            this = mlkinetics.KineticsKernel(varargin{:});
        end
    end

	methods
        
        function Q   = objectiveFunc(this, ps)
            %% OBJECTIVEFUNC returns the sum-of-square residuals for all cells of this.dependentData and corresponding
            %  this.estimateData.  Must fit is L1 caches.
            
            Q = sum((this.dependentData - this.estimateData(ps)).^2./ ...
                    (2*this.dependentData));
            if (Q < 10*eps)
                Q = Q + (1 + rand(1))*10*eps; 
            end
        end
		  
 		function this = KineticsKernel(ati, asai, st, ssa)
 			%% KINETICSKERNEL
            %  @param aifTimesInterp            is numeric;
            %  @param aifSpecificActivityInterp is numeric;
            %  @param independentData           is numeric;
            %  @param dependentData             is numeric;

            this = this@mlbayesian.NullKernel(st, ssa);            
            assert(isnumeric(ati));
            assert(isnumeric(asai)); 			
            this.aifTimesInterp            = ati;
            this.aifSpecificActivityInterp = asai;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

