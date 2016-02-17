classdef F18 
	%% F18  

	%  $Revision$
 	%  was created 08-Feb-2016 18:31:35
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties (Constant)        
        LAMBDA           = 0.95          % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY_18F = 0.00010524120 % k | dq/dt = -kq, for activity q of [18F] with half-life = 109.771(20) min = 6586.27(20) s
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

