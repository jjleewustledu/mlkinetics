classdef (Abstract) AbstractKineticsBuilder < mlkinetics.IKineticsBuilder
	%% ABSTRACTKINETICSBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 20:18:51 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)        
        model
 		solver
 		useSynthetic
 	end

	methods 
        
        %% GET
        
        function g = get.model(this)
            g = this.solver_.model;
        end
        function g = get.roisBuilder(this)
            g = this.roisBuilder_;
        end
        function g = get.solver(this)
            g = this.solver_;
        end
        function g = get.useSynthetic(this)
            g = this.solver_.useSynthetic;
        end
        
        function this = set.model(this, s)
            this.solver_.model = s;
        end
        function this = set.useSynthetic(this, tf)
            assert(islogical(tf));
            this.solver_.useSynthetic = tf;
        end
        
        %%   
        
        function diagnose(this, varargin)
            this.solver_.diagnose(varargin{:});
        end
        function fprintf(this, s)
            assert(ischar(s));
            fprintf('%s:%s', class(this), s);
        end
        function plot(this, varargin)
            this.solver_.plotAnnealing;
            this.solver_.plotParameterCovariances;
            this.solver_.plotLogProbabilityQC;
            this.solver_.histStdOfError;
        end
        function save(this)
            this.solver_.save;
        end
        function saveas(this, varargin)
            this.solver_.saveas(varargin{:});
        end
        function saveFigures(this)
            saveFigures(sprintf('fig_%s', this.solver_.fqfileprefix));
        end
        function writetable(this, varargin)
            this.solver_.model.writetable(varargin{:});
        end
		  
 		function this = AbstractKineticsBuilder(varargin)
 			%% ABSTRACTKINETICSBUILDER
 			%  @param named solver is an mlanalysis.ISolver
            
            ip = inputParser;
            addParameter(ip, 'solver', @(x) isa(x, 'mlanalysis.ISolver'));
            parse(ip, varargin{:});
 	
            this.solver_ = ip.Results.solver;
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        solver_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

