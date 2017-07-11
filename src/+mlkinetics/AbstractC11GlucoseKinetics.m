classdef AbstractC11GlucoseKinetics < mlkinetics.AbstractGlucoseKinetics
	%% ABSTRACTC11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		LC = 1
 	end

	methods 
        
        %%
		  
        function lg   = logging(this)
            lg = mlpipeline.Logger(this.fqfileprefix);
            if (isempty(this.summary))
                return
            end
            s = this.summary;
            lg.add('\n%s is working in %s\n', mfilename, pwd);
            if (~isempty(this.theSolver))
                lg.add('bestFitParams / s^{-1} -> %s\n', mat2str(s.bestFitParams));
                lg.add('meanParams / s^{-1} -> %s\n', mat2str(s.meanParams));
                lg.add('stdParams / s^{-1} -> %s\n', mat2str(s.stdParams));
                lg.add('std([[k_{21} k_{21} k_{32} k_{43}]] / min^{-1}) -> %s\n', mat2str(s.sdpar));
            end
            lg.add('[k_{21} k_{12} k_{32} k_{43}] / min^{-1} -> %s\n', mat2str(s.kmin));
            lg.add('LC -> %s\n', mat2str(s.LC));
            lg.add('chi = frac{k_{21} k_{32}}{k_{12} + k_{32}} / min^{-1} -> %s\n', mat2str(s.chi));
            lg.add('K_d = K_1 = V_B k_{21} / (mL min^{-1} hg^{-1}) -> %s\n', mat2str(s.Kd)); 
            lg.add('CTX_{glc} = [glc] K_1 / (\mu mol min^{-1} hg^{-1}) -> %s\n', mat2str(s.CTX)); 
            lg.add('CMR_{glc} = [glc] V_B chi / (\mu mol min^{-1} hg^{-1}) -> %s\n', mat2str(s.CMR));
            lg.add('free glc = CMRglc/(100 k_{32}) / (\mu mol/g) -> %s\n', mat2str(s.free));
            lg.add('mnii.count -> %i\n', s.maskCount);
            lg.add('sessd.parcellation -> %s\n', s.parcellation);
            lg.add('sessd.hct -> %g\n', s.hct);
            lg.add('\n');
        end
        function this = updateSummary(this)
            summary.class = class(this);
            summary.datestr = datestr(now, 30);
            if (~isempty(this.theSolver))
                summary.bestFitParams = this.bestFitParams;
                summary.meanParams = this.meanParams;
                summary.stdParams  = this.stdParams;
                summary.sdpar = 60*this.annealingSdpar(2:5);
            end
            summary.kmin = 60*[this.k21 this.k12 this.k32 this.k43];
            summary.LC = this.LC;
            summary.chi = summary.kmin(1)*summary.kmin(3)/(summary.kmin(2) + summary.kmin(3));
            summary.Kd = 100*this.v1*summary.kmin(1);
            summary.CTX = this.bloodGlucose*summary.Kd;
            summary.CMR = this.bloodGlucose*(100*this.v1)*(1/summary.LC)*summary.chi;
            summary.free = summary.CMR/(100*summary.kmin(3));    
            summary.maskCount = nan;
            if (~isempty(this.mask))
                mnii = mlfourd.MaskingNIfTId(this.mask.niftid);
                summary.maskCount = mnii.count;
            else
                summary.maskCount = nan;
            end
            summary.parcellation = this.sessionData.parcellation;
            summary.hct = this.hct;
            this.summary = summary;
        end
        
 		function this = AbstractC11GlucoseKinetics(varargin)
 			%% ABSTRACTC11GLUCOSEKINETICS
 			%  Usage:  this = AbstractC11GlucoseKinetics()

 			this = this@mlkinetics.AbstractGlucoseKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

