classdef (Abstract) IKineticsModel < mlanalysis.IModel
	%% IKINETICSMODEL  

	%  $Revision$
 	%  was created 12-Dec-2017 16:39:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Abstract) 
        aifSpecificActivity
        aifSpecificActivityInterp
        aifTimes
        aifTimesInterp
        scannerSpecificActivity
        scannerSpecificActivityInterp
        scannerTimes
        scannerTimesInterp		
        sessionData
 	end
    
    methods (Static, Abstract)
        Cwb = plasma2wb(Cp,  hct, ~)
        Cp  = wb2plasma(Cwb, hct, ~)
    end
    
	methods (Abstract)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

