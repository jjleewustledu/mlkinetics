classdef Huang1980 
	%% HUANG1980 
    %  See also:  American Journal of Physiology-Endocrinology and Metabolism 238(1) E69-E82 (1980).

	%  $Revision$
 	%  was created 16-Feb-2018 19:05:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties   
        LC = 0.64 % Powers, et al., JCBFM 31(5) 1223-1228, 2011.
        %LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
    end

    methods (Static)
        function alpha_ = a(k2, k3, k4)
            k234   = k2 + k3 + k4;
            alpha_ = k234 - sqrt(k234^2 - 4*k2*k4);
            alpha_ = alpha_/2;
        end
        function beta_  = b(k2, k3, k4)
            k234  = k2 + k3 + k4;
            beta_ = k234 + sqrt(k234^2 - 4*k2*k4);
            beta_ = beta_/2;
        end
        function q      = q2(Cp, K1, a, b, k4, t)
            scale = K1/(b - a);
            q = scale * conv((k4 - a)*exp(-a*t) + (b - k4)*exp(-b*t), Cp);
            q = q(1:length(t));
        end
        function q      = q3(Cp, K1, a, b, k3, t)
            scale = k3*K1/(b - a);
            q = scale * conv(exp(-a*t) - exp(-b*t), Cp);
            q = q(1:length(t));
        end
        function qT     = qpet(ks, Cp, t)
            K1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);  
            
            import mlkinetics.*;
            a  = Huang1980.a(k2, k3, k4);
            b  = Huang1980.b(k2, k3, k4);
            qT = Huang1980.q2(Cp, K1, a, b, k4, t) + ...
                 Huang1980.q3(Cp, K1, a, b, k3, t);
            qT = double(qT);
        end        
        function Cp  = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            import mlkinetics.Huang1980.*;
            Cp = Cwb./(1 + hct*(rbcOverPlasma(t) - 1));
        end
        function rop = rbcOverPlasma(t)
            %% RBCOVERPLASMA is [FDG(RBC)]/[FDG(plasma)]
            
            t   = t/60;      % sec -> min
            a0  = 0.814104;  % FINAL STATS param  a0 mean  0.814192	 std 0.004405
            a1  = 0.000680;  % FINAL STATS param  a1 mean  0.001042	 std 0.000636
            a2  = 0.103307;  % FINAL STATS param  a2 mean  0.157897	 std 0.110695
            tau = 50.052431; % FINAL STATS param tau mean  116.239401	 std 51.979195
            rop = a0 + a1*t + a2*(1 - exp(-t/tau));
        end
    end
    
	methods 
        function img  = buildCmrglcMap(this) 
            %  @return units of [CMRglc] == (mg/dL)(1/min)(mL/hg).
            
            warning('off', 'optimlib:lsqlin:WillRunDiffAlg');
            sz     = this.scanner_.size;
            mskImg = this.scanner_.mask.img;
            img    = zeros(sz(1),sz(2),sz(3));
            if (strcmp(getenv('TEST_HERSCOVITCH1985'), '1'))
                zrng = ceil(sz(3)/2):ceil(sz(3)/2);
                yrng = ceil(sz(2)/2):ceil(sz(2)/2)+10;
                xrng = ceil(sz(2)/2):ceil(sz(2)/2)+10;
            else
                zrng = 1:sz(3);
                yrng = 1:sz(2);
                xrng = 1:sz(1);
            end
            for z = zrng
                for y = yrng
                    for x = xrng 
                        if (mskImg(x,y,z))
                            img(x,y,z) = this.buildCmrglcNonlinear([x y z]);
                        end
                    end
                end
            end
            img = img * this.glc_ / this.LC; 
            warning('on', 'optimlib:lsqlin:WillRunDiffAlg');
        end
        function vox = buildCmrglcNonlinear(this, xvec)
            %% BUILDCMRGLCNONLINEAR calls lsqcurvefit.
            %  @return vox is numeric.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            import mlkinetics.*;
            rng_s = this.scanner_.index0:this.scanner_.indexF;
            qT    = ensureRowVector(squeeze(this.scanner_.specificActivity(xvec(1),xvec(2),xvec(3),rng_s))); 
            anon  = @(ks__,t__)Huang1980.qpet(ks__, this.Cp_, t__);
            [ks,~,~,exitflag] = ...
                    lsqcurvefit(anon, this.ks0_, this.t_, qT, this.lb_, this.ub_);
            disp(ks)
            %disp(resnorm)
            %disp(residual)
            disp(exitflag)
            vox = 60*ks(1)*ks(3)/(ks(2) + ks(3)); % 60 mL/g/s -> mL/g/min
        end
		  
 		function this = Huang1980(varargin)
 			%% Huang1980
 			%  Usage:  this = Huang1980()

 			ip = inputParser;
            addParameter(ip, 'aif',     [], @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'cbv',     [], @(x) isa(x, 'mlfourd.INIfTI') || isempty(x));
            addParameter(ip, 'glc',     [], @isscalar);
            addParameter(ip, 'hct',     [], @isscalar);
            addParameter(ip, 'LC', this.LC, @isnumeric);
            parse(ip, varargin{:});            
            this.aif_     = ip.Results.aif;
            this.scanner_ = ip.Results.scanner;
            this.cbv_     = ip.Results.cbv;
            this.glc_     = ip.Results.glc;
            this.hct_     = ip.Results.hct;
            this.LC       = ip.Results.LC;
            
            rng_s     = this.scanner_.index0:this.scanner_.indexF;
            t         = this.scanner_.times(rng_s);
            rng_a     = this.aif_.index0:this.aif_.indexF;
            Cwb       = pchip([0 this.aif_.times(rng_a)], [0 this.aif_.specificActivity(rng_a)], t);
            this.Cp_  = ensureRowVector(this.wb2plasma(Cwb, this.hct_, t));
            this.t_   = ensureRowVector(t);
            this.ks0_ = [4 0.3 0.2 0.01]/60;
            this.lb_  = this.ks0_/1000;
            this.ub_  = this.ks0_*1000;
 		end
    end 
    
    %% PRIVATE
    
	properties (Access = private)
 		aif_
        Cp_
        scanner_
        cbv_
        glc_
        hct_
        ks0_
        lb_
        t_
        ub_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

