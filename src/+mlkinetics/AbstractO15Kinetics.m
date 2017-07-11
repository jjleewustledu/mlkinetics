classdef AbstractO15Kinetics < mlkinetics.AbstractKinetics
	%% ABSTRACTO15KINETICS  

	%  $Revision$
 	%  was created 05-Jul-2017 20:04:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
    end
    
    properties (Dependent)
        hct
        crv
        tsc
    end

	methods 	
        
        %% GET/SET
        
        function g    = get.hct(this)
            g = this.sessionData.hct;
        end
        function g    = get.crv(this)
            g = this.crv_;
        end
        function this = set.crv(this, s)
            if (isempty(s))
                this = this.prepareArterialData;
                return
            end
            assert(isa(s, 'mlpet.IAifData') || isa(s, 'mlpet.IWellData') || isstruct(s));
            this.crv_ = s;
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
        
        function        plot(this, varargin)
            figure;
            max_crv = max(     this.crv.specificActivity);
            max_dcv = max(     this.dcv.specificActivity);
            max_tsc = max([max(this.tsc.specificActivity)  max(this.itsQpet)]);
            plot(this.crv.times, this.crv.specificActivity/max_crv, '-o',  ...
                 this.dcv.times, this.dcv.specificActivity/max_dcv, '-s',  ...
                 this.tsc.times, this.tsc.specificActivity/max_tsc, '-d', ...
                 this.times{1},  this.itsQpet             /max_tsc, varargin{:});
            legend('data CRV', 'Bayesian DCV', 'data TSC', 'Bayesian TSC');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s\nrescaled by %g, %g, %g', this.yLabel,  max_crv, max_dcv, max_tsc));
        end
        
 		function this = AbstractO15Kinetics(varargin)
 			%% ABSTRACTO15KINETICS
 			%  Usage:  this = AbstractO15Kinetics()

 			this = this@mlkinetics.AbstractKinetics(varargin{:});
 		end
 	end 
    
    %% PRIVATE
    
    properties (Access = protected)
        hct_
        crv_
        tsc_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

