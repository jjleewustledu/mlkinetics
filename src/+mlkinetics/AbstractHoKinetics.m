classdef AbstractHoKinetics < mlkinetics.AbstractO15Kinetics
	%% ABSTRACTHOKINETICS uses only scannerROI(t), t < 60 s.

	%  $Revision$
 	%  was created 05-Jul-2017 20:03:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        
 	end
    
    methods (Static)
    end

	methods	
        
 		function this = AbstractHoKinetics(varargin)
 			%% ABSTRACTHOKINETICS
 			%  Usage:  this = AbstractHoKinetics()

 			this = this@mlkinetics.AbstractO15Kinetics(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

