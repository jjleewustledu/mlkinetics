classdef Huang1980 
	%% HUANG1980  

	%  $Revision$
 	%  was created 01-Jan-2020 21:54:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		aif
        cbv
        glc
        hct
 		LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
        scanner
    end
    
    properties (Dependent)
        artery_interpolated
        recon_times
    end
    
    methods (Static)
        function qs = huang1980_solution(ks, v1, artery_interpolated)
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            scale = 1;
            
            n = length(artery_interpolated);
            times = 0:1:n-1;
            k234 = k2 + k3 + k4;         
            bminusa = sqrt(k234^2 - 4 * k2 * k4);
            alpha = 0.5 * (k234 - bminusa);
            beta  = 0.5 * (k234 + bminusa);   
            conva = conv(exp(-alpha .* times), artery_interpolated);
            convb = conv(exp(-beta  .* times), artery_interpolated);
            conva = conva(1:n);
            convb = convb(1:n);
            conv2 = (k4 - alpha) .* conva + (beta - k4) .* convb;
            conv3 =                 conva -                convb;
            q2 = (k1 / bminusa)      * conv2;
            q3 = (k3 * k1 / bminusa) * conv3;
            qs = v1 * (artery_interpolated + scale * (q2 + q3));            
        end
        function qs = huang1980_sampled(ks, v1, artery_interpolated, recon_times)
            import mlkinetics.Huang1980.huang1980_solution  
            qs = huang1980_solution(ks, v1, artery_interpolated);
            qs = qs(ceil(recon_times));
        end
        function [dqs,qs] = grad_huang1980_solution(ks, v1, artery_interpolated)
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            scale = 1;
            
            n = length(artery_interpolated);
            times = 0:1:n-1;
            k234 = k2 + k3 + k4;
            bminusa = sqrt(k234^2 - 4 * k2 * k4);
            alpha = 0.5 * (k234 - bminusa);
            beta  = 0.5 * (k234 + bminusa);
            conva  = conv(exp(-alpha .* times),          artery_interpolated);
            convb  = conv(exp(-beta  .* times),          artery_interpolated);
            convta = conv(exp(-alpha .* times) .* times, artery_interpolated);
            convtb = conv(exp(-beta  .* times) .* times, artery_interpolated);
            conva  = conva( 1:n);
            convb  = convb( 1:n);  
            convta = convta(1:n);
            convtb = convtb(1:n);            
            conv2  = (k4 - alpha) * conva + (beta - k4) * convb;
            conv3  =                conva -               convb;
            
            q2 = (k1 / bminusa)      * conv2;
            q3 = (k3 * k1 / bminusa) * conv3;
            qs = v1 * (artery_interpolated + scale * (q2 + q3)); 

            part_bminusa_k2 = (k234 - 2 * k4) / bminusa;
            part_a_k2 = 0.5 * (1 - part_bminusa_k2);
            part_b_k2 = 0.5 * (1 + part_bminusa_k2);

            part_bminusa_k3 =  k234 / bminusa;
            part_a_k3 = 0.5 * (1 - part_bminusa_k3);
            part_b_k3 = 0.5 * (1 + part_bminusa_k3);

            part_bminusa_k4 = (k234 - 2 * k2) / bminusa;
            part_a_k4 = 0.5 * (1 - part_bminusa_k4);
            part_b_k4 = 0.5 * (1 + part_bminusa_k4);
            
            part_q2_k1 = (1/bminusa) * conv2;
            
            part_q2_k2 = ...
                -(k1 * part_bminusa_k2 / bminusa^2) * conv2 + ...
                 (k1 / bminusa) * ( ...
                     part_a_k2 * (-conva - (k4 - alpha) * convta) + ...
                     part_b_k2 * ( convb - (beta - k4)  * convtb) ...
                 );
            
            part_q2_k3 = ...
                -(k1 * part_bminusa_k3 / bminusa^2) * conv2 + ...
                 (k1 / bminusa) * ( ...
                     part_a_k3 * (-conva - (k4 - alpha) * convta) + ...
                     part_b_k3 * ( convb - (beta - k4)  * convtb) ...
                 );
            
            part_q2_k4 = ...
                -(k1 * part_bminusa_k4 / bminusa^2) * conv2 + ...
                 (k1 / bminusa) * ( ...
                     conva - ...
                     part_a_k4 * conva -...
                     part_a_k4 * (k4 - alpha) * convta + ...
                     part_b_k4 * convb - ...
                     convb - ...
                     part_b_k4 * (beta - k4)  * convtb ...
                 );

            part_q3_k1 = (k3 / bminusa) * conv3;
            
            part_q3_k2 = ...
                -(k3 * k1 * part_bminusa_k2 / bminusa^2) * conv3 - ...
                 (k3 * k1 / bminusa) * ( ...
                     -part_a_k2 * convta + ...
                      part_b_k2 * convtb ...
                 );
            
            part_q3_k3 = ...
                (k1 / bminusa) * conv3 -  ...
                (k3 * k1 * part_bminusa_k3 / bminusa^2) * conv3 + ...
                (k3 * k1 / bminusa) * ( ...
                    -part_a_k3 * convta + ...
                     part_b_k3 * convtb ...
                );
            
            part_q3_k4 = ...
                -(k3 * k1 * part_bminusa_k4 / bminusa^2) * conv3 + ...
                 (k3 * k1 / bminusa) * ( ...
                     -part_a_k4 * convta + ...
                      part_b_k4 * convtb ...
                 );
            
            part_qs_k1 = part_q2_k1 + part_q3_k1; 
            part_qs_k2 = part_q2_k2 + part_q3_k2; 
            part_qs_k3 = part_q2_k3 + part_q3_k3; 
            part_qs_k4 = part_q2_k4 + part_q3_k4;
            dqs = v1 * scale * [part_qs_k1; part_qs_k2; part_qs_k3; part_qs_k4];
        end
        function [dqs,qs] = grad_huang1980_sampled(ks, v1, artery_interpolated, recon_times)
            import mlkinetics.Huang1980.grad_huang1980_solution  
            [dqs,qs] = grad_huang1980_solution(ks, v1, artery_interpolated);
            dqs = dqs(:, ceil(recon_times)); % kBq*s/mL
            qs  =  qs(:, ceil(recon_times)); % kBq/mL
        end     
        
        function logp = log_likelihood(Z, Sigma)
            logp = sum(-log(Sigma) - 0.5*log(2*pi) - 0.5*Z.^2); % scalar
        end
        function dks  = grad_ks(dqs, Z, Sigma)
            dks = dqs*Z./Sigma; % 4 x 1
        end
        
        function midt = end_times_to_mid_times(endt)
            midt = nan(size(endt));
            midt(1) = endt(1)/2;
            for it = 2:length(endt)
                midt(it) = endt(it-1) + (endt(it) - endt(it-1))/2;
            end
        end
        function rop  = rbc_over_plasma(t)
            %% RBCOVERPLASMA is [FDG(RBC)]/[FDG(plasma)]
            
            t   = t/60;      % sec -> min
            a0  = 0.814104;  % FINAL STATS param  a0 mean  0.814192	 std 0.004405
            a1  = 0.000680;  % FINAL STATS param  a1 mean  0.001042	 std 0.000636
            a2  = 0.103307;  % FINAL STATS param  a2 mean  0.157897	 std 0.110695
            tau = 50.052431; % FINAL STATS param tau mean  116.239401	 std 51.979195
            rop = a0 + a1*t + a2*(1 - exp(-t/tau));
        end
        function Cp   = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            import mlkinetics.Huang1980.rbc_over_plasma;
            Cp = Cwb./(1 + hct*(rbc_over_plasma(t) - 1));
        end
    end

	methods		  
        
        %% GET
        
        function g = get.artery_interpolated(this)
            rtimes = this.recon_times;
            rng = this.aif.index0:this.aif.indexF;
            if (this.aif.times(1) > 0)
                Cwb = makima([0 this.aif.times(rng)], [0 this.aif.specificActivity(rng)], 0:rtimes(end));
            else
                Cwb = makima(   this.aif.times(rng),     this.aif.specificActivity(rng),  0:rtimes(end));
            end
            g = ensureRowVector(this.wb2plasma(Cwb, this.hct, 0:rtimes(end)));
        end
        function g = get.recon_times(this)
            import mlkinetics.Huang1980.end_times_to_mid_times
            rng = this.scanner.index0:this.scanner.indexF;
            g   = this.scanner.times(rng);
            g   = end_times_to_mid_times(g);
        end
        
        %%
        
 		function this = Huang1980(varargin)
 			%% HUANG1980
 			%  @param aif has scalar properties:  index0, indexF; vector properties:  times, specificActivity.
 			%  @param scanner ".
 			%  @param cbv.
 			%  @param glc is scalar.
 			%  @param hct is scalar.
 			%  @param LC  is scalar.
 			
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'aif',     [])
            addParameter(ip, 'scanner', [])
            addParameter(ip, 'cbv',     [])
            addParameter(ip, 'glc',     [], @isscalar)
            addParameter(ip, 'hct',     [], @isscalar)
            addParameter(ip, 'LC', this.LC, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.aif     = ipr.aif;
            this.scanner = ipr.scanner;
            this.cbv     = ipr.cbv;
            this.glc     = ipr.glc;
            this.hct     = ipr.hct;
            this.LC      = ipr.LC;            
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

