classdef AbstractC11GlucoseKinetics < mlkinetics.AbstractGlucoseKinetics
	%% ABSTRACTC11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = AbstractC11GlucoseKinetics(varargin)
 			%% ABSTRACTC11GLUCOSEKINETICS
 			%  Usage:  this = AbstractC11GlucoseKinetics()

 			this = this@mlkinetics.AbstractGlucoseKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

