classdef (Abstract) AbstractKineticsDirector < mlkinetics.IKineticsDirector
	%% ABSTRACTKINETICSDIRECTOR provides methods:  diagnose, plot, writetable.

	%  $Revision$
 	%  was created 12-Dec-2017 19:27:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        builder
        useSynthetic
 	end

	methods 
        
        %% GET/SET
        
        function g = get.builder(this)
            g = this.kineticsBuilder_;
        end
        function g = get.useSynthetic(this)
            g = this.kineticsBuilder_.useSynthetic;
        end        
        
        function this = set.useSynthetic(this, tf)
            assert(islogical(tf));
            this.kineticsBuilder_.useSynthetic = tf;
        end
		  
        %%        
        
        function diagnose(this, varargin)
            this.kineticsBuilder_.diagnose(varargin{:});
        end
        function plot(this, varargin)
            this.kineticsBuilder_.plot(varargin{:});
        end
        function report(this, varargin)
            this.plot(varargin{:});
            this.writetable(varargin{:});
            this.save;
        end
        function save(this)
            this.kineticsBuilder_.save;
        end
        function writetable(this, varargin)
            this.kineticsBuilder_.writetable(varargin{:});
        end
        
 	end 

    %% PROTECTED
    
    properties (Access = protected)        
        kineticsBuilder_
        physiologicals_
        rates_  
        roisBuilder_
    end
    
    methods (Access = protected)
        function this = AbstractKineticsDirector(varargin)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

