classdef (Abstract) AbstractIterableKineticsDirector < mlkinetics.AbstractKineticsDirector & mlpatterns.IIterable
	%% ABSTRACTITERABLEKINETICSDIRECTOR supports mlpatterns.Iterator for regions.

	%  $Revision$
 	%  was created 14-Jan-2018 22:50:20 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        iterator
 	end

	methods 
		  
        %% GET        
        
        function g = get.iterator(this)
            g = mlrois.RoisIterator(this);
            error('mlkinetics:notImplemented', 'AbstractKineticsDirector.get.iterator');
        end
        
        %%
        
 		function this = AbstractIterableKineticsDirector(varargin)
 			%% ABSTRACTITERABLEKINETICSDIRECTOR

 			this = this@mlkinetics.AbstractKineticsDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

