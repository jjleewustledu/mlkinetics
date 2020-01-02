classdef Huang1980Nonlinear 
	%% HUANG1980NONLINEAR 
    %  See also:  American Journal of Physiology-Endocrinology and Metabolism 238(1) E69-E82 (1980).

	%  $Revision$
 	%  was created 16-Feb-2018 19:05:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        V = 0.038 % blood volume fraction
    end
    
    properties   
        LC = 0.64 % Powers, et al., JCBFM 31(5) 1223-1228, 2011.
        %LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
        nSamples = [] % for testing
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
            Dt = ks(5); % shift Cp
            
            import mlkinetics.*;
            Cp = Huang1980Nonlinear.slide(Cp, t, Dt);
            a  = Huang1980Nonlinear.a(k2, k3, k4);
            b  = Huang1980Nonlinear.b(k2, k3, k4);
            qT = Huang1980Nonlinear.q2(Cp, K1, a, b, k4, t) + ...
                 Huang1980Nonlinear.q3(Cp, K1, a, b, k3, t) + Huang1980Nonlinear.V*Cp; 
            qT = double(qT);
        end     
        function conc    = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlbayesian.*;
            [conc,trans] = AbstractBayesianStrategy.ensureRow(conc);
            t            = AbstractBayesianStrategy.ensureRow(t);
            
            tspan = t(end) - t(1);
            tinc  = t(2) - t(1);
            t_    = [(t - tspan - tinc) t];   % prepend times
            conc_ = [zeros(size(conc)) conc]; % prepend zeros
            conc_(isnan(conc_)) = 0;
            conc  = pchip(t_, conc_, t - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts to right
            
            if (trans)
                conc = conc';
            end
        end   
        function Cp  = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            import mlkinetics.Huang1980Nonlinear.*;
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
        function [cmrglc,ks,synth]  = buildCmrglcMap(this) 
            %  @return units of [CMRglc] == (mg/dL)(1/min)(mL/hg).
            
            warning('off', 'optimlib:lsqlin:WillRunDiffAlg');
            switch (this.resampler_.ndims) % R^{d+1}
                case 2
                    [Ki,ks,synth] = this.buildCmrglcMap1;
                case 3
                    [Ki,ks,synth] = this.buildCmrglcMap2;
                case 4
                    [Ki,ks,synth] = this.buildCmrglcMap3;
                otherwise
                    error('mlkinetics:unsupportedSwitchcase', ...
                          'Huang1980Nonlinear.buildCmrglcMap.this.scanner_.mask.ndims->%i', this.resampler_.ndims);
            end 
            warning('on', 'optimlib:lsqlin:WillRunDiffAlg');
            
            % assemble physiologic units
            cmrglc = Ki * this.glc_ / this.LC; % [CMRglc] := (mL/g/min) (mg/dL)
            if (this.useSI_)
                cmrglc = 0.05551 * cmrglc; % 100 * % g to hg conversion issue?
                % [CMRglc] := \mumol/(min hg) ==
                % (1/min)(mL/g)(mg/dL) x 100 (g/hg) x 0.05551 [\mumol/mL][dL/mg]
            end
            if (this.resampler_.ndims < 3)
                t = table(cmrglc, ks(1), ks(2), ks(3), ks(4), ks(5), 'VariableNames', {'cmrglc' 'K1' 'k2' 'k3' 'k4' 'Dt'});
                writetable(t, [this.resampler_.fqfileprefix '.txt']);
            end
        end
		  
 		function this = Huang1980Nonlinear(varargin)
 			%% Huang1980Nonlinear
 			%  Usage:  this = Huang1980Nonlinear()

 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'aif',       [], @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'scanner',   [], @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'resampler', [], @(x) isa(x, 'mlfourd.AbstractResampler'));
            addParameter(ip, 'cbv',       [], @(x) isa(x, 'mlfourd.INIfTI') || isempty(x));
            addParameter(ip, 'glc',       [], @isscalar);
            addParameter(ip, 'hct',       [], @isscalar);
            addParameter(ip, 'LC', this.LC,   @isnumeric);
            addParameter(ip, 'useSI', true,   @islogical);
            addParameter(ip, 'logger', mlpipeline.Logger(tmpFileprefix), @(x) isa(x, 'mlpipeline.Logger'));
            parse(ip, varargin{:});            
            this.aif_       = ip.Results.aif;
            this.scanner_   = ip.Results.scanner;
            this.resampler_ = ip.Results.resampler;
            this.cbv_       = ip.Results.cbv;
            this.glc_       = ip.Results.glc;
            this.hct_       = ip.Results.hct;
            this.LC         = ip.Results.LC;
            this.useSI_     = ip.Results.useSI;
            this.logger_    = ip.Results.logger;
            
            rng_s     = this.scanner_.index0:this.scanner_.indexF;
            t         = this.scanner_.times(rng_s);
            d         = this.resampler_.dynamic;
            this.dynamic_ = d.niftid;
            m         = this.resampler_.mask;
            this.mask_ = m.niftid;
            rng_a     = this.aif_.index0:this.aif_.indexF;
            if (this.aif_.times(1) > 0)
                Cwb   = pchip([0 this.aif_.times(rng_a)], [0 this.aif_.specificActivity(rng_a)], t);
            else
                Cwb   = pchip(   this.aif_.times(rng_a),     this.aif_.specificActivity(rng_a), t);
            end
            this.Cp_  = ensureRowVector(this.wb2plasma(Cwb, this.hct_, t));
            this.t_   = double(ensureRowVector(t));
            this.ks0_ = [4 0.3 0.2 0.01]/60;
            this.ks0_ = [this.ks0_ -4];
            this.lb_  = []; %[0 0 0 0 -120];
            this.ub_  = []; %[this.ks0_(1:4)*1024 0];
            this.options_ = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt');
 		end
    end 
    
    %% PRIVATE
    
	properties (Access = private)
 		aif_
        Cp_
        dynamic_
        mask_
        options_
        scanner_
        resampler_
        cbv_
        glc_
        hct_
        ks0_
        lb_
        logger_
        t_
        ub_
        useSI_
    end
    
    methods (Access = private)
        function [Ki,ks,synth] = buildCmrglcMap1(this) 
            %  @return units of [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
            
            [Ki,ks,synth] = this.buildCmrglcNonlinear1;
        end
        function [Ki,ks,synth] = buildCmrglcMap2(this) 
            %  @return units of [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
            
            sz     = this.mask_.size;
            Ki     = zeros(sz(1),sz(2));
            ks     = zeros(sz(1),sz(2), length(this.ks0_));
            synth  = zeros(sz(1),sz(2),length(this.t_));
            smpls  = 0;
            yrng   = 1:sz(2);
            xrng   = 1:sz(1);
            for y = yrng
                for x = xrng 
                    if (this.mask_.img(x,y))
                        smpls = smpls + 1;
                        if (isempty(this.nSamples) || smpls <= this.nSamples)
                            [Ki(x,y),ks(x,y,:),synth(x,y,:)] = this.buildCmrglcNonlinear2([x y]);
                        end
                    end
                end
            end
        end
        function [Ki,ks,synth] = buildCmrglcMap3(this) 
            %  @return units of [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
            
            sz     = this.mask_.size;
            Ki     = zeros(sz(1),sz(2),sz(3));
            ks     = zeros(sz(1),sz(2),sz(3), length(this.ks0_));
            synth  = zeros(sz(1),sz(2),sz(3),length(this.t_));
            smpls  = 0;
            zrng   = 1:sz(3);
            yrng   = 1:sz(2);
            xrng   = 1:sz(1);
            for z = zrng
                for y = yrng
                    for x = xrng 
                        if (this.mask_.img(x,y,z))
                            smpls = smpls + 1;
                            if (isempty(this.nSamples) || smpls <= this.nSamples)                                
                                [Ki(x,y,z),ks(x,y,z,:),synth(x,y,z,:)] = this.buildCmrglcNonlinear3([x y z]);
                            end
                        end
                    end
                end
            end
        end
        function [Ki,ks,synth] = buildCmrglcNonlinear1(this, varargin)
            %% BUILDCMRGLCNONLINEAR calls lsqcurvefit.
            %  @return vox is numeric.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            import mlkinetics.*;
            rng_s = this.scanner_.index0:this.scanner_.indexF;
            qT    = double(ensureRowVector(squeeze(this.dynamic_.img(rng_s)))); 
            anon  = @(ks__,t__)Huang1980Nonlinear.qpet(ks__, this.Cp_, t__);
            [ks,~,~,exitflag] = ...
                    lsqcurvefit(anon, this.ks0_, this.t_, qT, this.lb_, this.ub_, this.options_);
            disp(ks)
            %disp(resnorm)
            %disp(residual)
            disp(exitflag)
            synth = anon(ks, this.t_);
            ks(1:4) = 60 * ks(1:4); % [ks] := [mL/g/min 1/min 1/min 1/min] == 60 [mL/g/s 1/s 1/s 1/s ]
            Ki = ks(1)*ks(3)/(ks(2) + ks(3)); % [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
        end
        function [Ki,ks,synth] = buildCmrglcNonlinear2(this, xvec)
            %% BUILDCMRGLCNONLINEAR calls lsqcurvefit.
            %  @return vox is numeric.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            import mlkinetics.*;
            rng_s = this.scanner_.index0:this.scanner_.indexF;
            qT    = ensureRowVector(squeeze(this.dynamic_.img(xvec(1),xvec(2),rng_s))); 
            anon  = @(ks__,t__)Huang1980Nonlinear.qpet(ks__, this.Cp_, t__);
            [ks,~,~,exitflag] = ...
                    lsqcurvefit(anon, this.ks0_, this.t_, qT, this.lb_, this.ub_, this.options_);
            disp(ks)
            %disp(resnorm)
            %disp(residual)
            disp(exitflag)
            synth = anon(ks, this.t_);
            ks(1:4) = 60 * ks(1:4); % [ks] := [mL/g/min 1/min 1/min 1/min] == 60 [mL/g/s 1/s 1/s 1/s ]
            Ki = ks(1)*ks(3)/(ks(2) + ks(3)); % [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
        end
        function [Ki,ks,synth] = buildCmrglcNonlinear3(this, xvec)
            %% BUILDCMRGLCNONLINEAR calls lsqcurvefit.
            %  @return vox is numeric.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            import mlkinetics.*;
            rng_s = this.scanner_.index0:this.scanner_.indexF;
            qT    = ensureRowVector(squeeze(this.dynamic_.img(xvec(1),xvec(2),xvec(3),rng_s))); 
            anon  = @(ks__,t__)Huang1980Nonlinear.qpet(ks__, this.Cp_, t__);
            [ks,~,~,exitflag] = ...
                    lsqcurvefit(anon, this.ks0_, this.t_, qT, this.lb_, this.ub_, this.options_);
            disp(ks)
            %disp(resnorm)
            %disp(residual)
            disp(exitflag)
            synth = anon(ks, this.t_);
            ks(1:4) = 60 * ks(1:4); % [ks] := [mL/g/min 1/min 1/min 1/min] == 60 [mL/g/s 1/s 1/s 1/s ]
            Ki = ks(1)*ks(3)/(ks(2) + ks(3)); % [Ki] == [K1 k3/(k2 + k3)] == mL/g/min
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

