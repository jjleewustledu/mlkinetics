classdef AbstractGlucoseKinetics < mlkinetics.AbstractKinetics
	%% ABSTRACTGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 24-Mar-2017 16:23:24 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    methods (Static, Abstract)
        Cwb = plasma2wb(Cp,  hct, ~)
        Cp  = wb2plasma(Cwb, hct, ~)
    end
    
    properties
        bloodGlucoseBlinding = true
    end
    
    properties (Dependent)
        bloodGlucose
        hct
        dta
        tsc
    end
    
    methods 
        
        %% GET/SET
        
        function g    = get.bloodGlucose(this)
            if (this.bloodGlucoseBlinding)
                g = nan;
                return
            end            
            g = this.sessionData.plasmaGlucose;
            g = 0.05551*g; % to SI
            g = this.plasma2wb(g, this.hct, 0);
        end
        function g    = get.hct(this)
            g = this.sessionData.hct;
        end
        function g    = get.dta(this)
            g = this.dta_;
        end
        function this = set.dta(this, s)
            if (isempty(s))
                this = this.prepareAifData;
                return
            end
            assert(isa(s, 'mlpet.IAifData') || isa(s, 'mlpet.IWellData') || isstruct(s));
            this.dta_ = s;
        end
        function g    = get.tsc(this)
            g = this.tsc_;
        end
        function this = set.tsc(this, s)
            if (isempty(s))
                this = this.prepareScannerData;
                return
            end
            assert(isa(s, 'mlpet.IScannerData') || isstruct(s))
            this.tsc_ = s;
        end
    
        %%
        
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
    
    %% PROTECTED
    
    properties (Access = protected)
        hct_
        dta_
        tsc_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

