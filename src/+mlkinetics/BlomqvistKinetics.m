classdef BlomqvistKinetics 
	%% BLOMQVISTKINETICS 
    %  See also:  J. Cereb. Blood Flow & Metab. 4:629-632 1984.

	%  $Revision$
 	%  was created 16-Feb-2018 19:05:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
    end

    methods (Static)
        function qT = qpet(Aa, ~, k1, k2, k3, qt, t, v1)
            % test:
            % t = 0:9; Aa = exp(-t/3); qt = 1 - exp(-t/3); 
            % qT = BlomqvistKinetics.qpet(Aa, [], 1, 1, 1, qt, t, 1) \sim t;
            % plot(t,Aa,t,qt)
            
            % disable for speed:
            % ssert(isrow(Aa) && isrow(qt) && isrow(t));
            % assert(all(size(Aa) == size(qt)) && ...
            %        all(size(qt) == size(t)));
            
            dt  = t(2:end) - t(1:end-1);
            dt  = [dt dt(end)];
            qT  = zeros(size(qt));
            
            Aa_dt_ = v1*Aa.*dt;
            qt_dt_ = qt .*dt;
            for i = 1:length(t)
                qT(i) = k1*trapz(Aa_dt_(1:i), 2) + ...
                        k1*k3*trapz(cumtrapz(Aa_dt_(1:i), 2).*dt(1:i), 2) - ...
                       (k2 + k3)*trapz(qt_dt_(1:i), 2);
            end
        end
    end
    
	methods 
        
        function this = buildKinetics(this, qt, ks0)
            %% BUILDMODELCBF 
            %  @param qt are numeric.
            %  @param qT are numeric.
            %  @returns this with this.product := mdl.  ks are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            mdl = fitnlm(ensureColVector(qt), ensureColVector(qT), @mlkinetics.BlomqvistKinetics.qpet, ks0);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(qt), max(qt));
            if (isempty(getenv(upper('TEST_HERSCOVITCH1985'))))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
            this.product_ = mdl;
        end
		  
 		function this = BlomqvistKinetics(varargin)
 			%% BLOMQVISTKINETICS
 			%  Usage:  this = BlomqvistKinetics()

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

