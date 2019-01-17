classdef (Abstract) IHandleKineticsDirector < matlab.mixin.Copyable
	%% IHANDLEKINETICSDIRECTOR  

	%  $Revision$
 	%  was created 17-Aug-2018 21:23:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
    end
    
	methods (Abstract)        
        constructBrainmaskEstimate(this)
        constructAvisRegionalEstimates(this)
        constructAparcAsegEstimates(this)
        constructAparcA2009sAsegEstimates(this)
        constructVoxelEstimates(this)
 	end 


	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

