classdef (Abstract) AbstractKineticsBuilder < handle & mlkinetics.IHandleKineticsBuilder
	%% ABSTRACTKINETICSBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 20:18:51 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        imagingContext
 		product
        verbose
 	end

	methods 
        
        %% GET      
                
        function g = get.imagingContext(this)
            g = this.imagingContext_;
        end   
        function g = get.product(this)
            g = this.product_;
        end    
        function g = get.verbose(this)
            g = this.verbose_;
        end
        
        %%   
        
        function addLog(this, varargin)
            this.imagingContext_.addLog(varargin{:});
        end
        function fprintf(this, s)
            assert(ischar(s));
            fprintf('%s:%s', class(this), s);
        end
        function saveFigures(this)
            saveFigures(sprintf('fig_%s', this.imagingContext.fqfileprefix));
        end
		  
 		function this = AbstractKineticsBuilder(varargin)
 			%% ABSTRACTKINETICSBUILDER
 			%  @param named 'verbose' is logical; default := true.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'verbose', true, @islogical);
            parse(ip, varargin{:});            
            this.verbose_ = ip.Results.verbose;
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        imagingContext_
        product_
        verbose_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

