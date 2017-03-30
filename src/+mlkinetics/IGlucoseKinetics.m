classdef IGlucoseKinetics 
	%% IGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 27-Mar-2017 17:23:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Abstract) 		
 		dta        % objects w/ fields times, specificActivity
        dtaNyquist
        notes
        tsc
        tscNyquist
 	end

	methods (Abstract)
		  
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

