classdef (Abstract) IKineticsDirector
	%% IKINETICSDIRECTOR  

	%  $Revision$
 	%  was created 14-Jan-2018 00:00:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
    
	properties (Abstract)
        builder
        product
        useSynthetic
    end
    
    methods (Abstract)
        diagnose(this, varargin)
        plot(this, varargin)
        report(this, varargin)
        save(this)
        writetable(this, varargin)
        
        this = constructRates(this)
        this = constructPhysiological(this)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

