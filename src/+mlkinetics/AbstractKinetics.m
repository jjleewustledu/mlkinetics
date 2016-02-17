classdef AbstractKinetics < mlbayesian.AbstractMcmcStrategy
	%% ABSTRACTKINETICS  

	%  $Revision$
 	%  was created 08-Feb-2016 20:02:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		
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
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

