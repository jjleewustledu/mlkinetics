classdef AbstractGlucoseKinetics < mlkinetics.AbstractKinetics & mlkinetics.IGlucoseKinetics
	%% ABSTRACTGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 24-Mar-2017 16:23:24 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		dta
        dtaNyquist
        tsc
        tscNyquist
    end
    
	methods 		  
 		function this = AbstractGlucoseKinetics(varargin)
 			%% ABSTRACTGLUCOSEKINETICS
 			%  Usage:  this = AbstractGlucoseKinetics()
 			
 			this = this@mlkinetics.AbstractKinetics(varargin{:}); 
 		end
        function        plot(this, varargin)
            figure;
            max_dta = max(     this.dta.specificActivity);
            max_tsc = max([max(this.tsc.specificActivity)  max(this.itsQpet)]);
            plot(this.dta.times, this.dta.specificActivity/max_dta, '-o',  ...
                 this.times{1},  this.itsQpet             /max_tsc, ...
                 this.tsc.times, this.tsc.specificActivity/max_tsc, '-s', varargin{:});
            legend('data DTA', 'Bayesian TSC', 'data TSC');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s\nrescaled by %g, %g', this.yLabel,  max_dta, max_tsc));
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

