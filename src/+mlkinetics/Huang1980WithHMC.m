classdef Huang1980WithHMC < mlstatistics.HMC
	%% HUANG1980WITHHMC  
    %  Background activity measured by well counter ~ 5 Bq/mL; 

	%  $Revision$
 	%  was created 27-Dec-2019 14:40:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        WELL_BACKGROUND = 0.005 % kBq/mL
    end
    
	properties
 		artery_interpolated
        csv_filename = '/Users/jjlee/Tmp/DeepNetFCProject/PET/ses-E03056/FDG_DT20190523132832.000000-Converted-AC/makima_ksactivities.csv'
        true_sigma_noise = 0.01
        recon_end_times = [10., 23., 37., 53., 70., 89., 109., 131., 154., 179., 205., 233., 262., 293., 325., 359., 394., 431., 469., 509., 550., 593., 637., 683., 730., 779., 829., 881., 934., 990., 1047., 1106., 1166., 1228., 1291., 1356., 1422., 1490., 1559., 1630., 1702., 1776., 1852., 1930., 2009., 2090., 2172., 2256., 2341., 2428., 2516., 2607., 2699., 2793., 2888., 2985., 3083., 3183., 3284., 3388., 3493., 3601.]
        recon_times
        true_ks
        true_qs
    end
    
    methods (Static)        
        function qs = huang1980_solution(ks, artery_interpolated)
            %import mlkinetics.Huang1980WithHMC.relu_pars
            %ks = relu_pars(ks, 4);
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            scale = 1;
            v1 = 0.04;  
            
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
        function qs = huang1980_sampled(ks, artery_interpolated, recon_times)
            import mlkinetics.Huang1980WithHMC.huang1980_solution  
            qs = huang1980_solution(ks, artery_interpolated);
            qs = qs(ceil(recon_times));
        end
        function [dqs,qs] = grad_huang1980_solution(ks, artery_interpolated)
            %import mlkinetics.Huang1980WithHMC.relu_pars
            %ks = relu_pars(ks, 4);
            k1 = ks(1);
            k2 = ks(2);
            k3 = ks(3);
            k4 = ks(4);
            scale = 1;
            v1 = 0.04;  
            
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
        function [dqs,qs] = grad_huang1980_sampled(ks, artery_interpolated, recon_times)
            import mlkinetics.Huang1980WithHMC.grad_huang1980_solution  
            [dqs,qs] = grad_huang1980_solution(ks, artery_interpolated);
            dqs = dqs(:, ceil(recon_times)); % kBq*s/mL
            qs  =  qs(:, ceil(recon_times)); % kBq/mL
        end
        
        function [logpost, grad_logpost] = log_posterior( ...
                Parameters, ts, qs, artery_interpolated, ...
                mean_ks, sigma_ks, ...
                mean_log_var_noise, sigma_log_var_noise)
            %% The |log_posterior| function returns the logarithm of the product of a
            %  normal likelihood and a normal prior for the model. The input
            %  argument |Parameter| has the format |[Beta;LogNoiseVariance]|.
            %  |tst| and |qst| contain the values of the predictors and response,
            %  respectively.
            
            import mlkinetics.Huang1980WithHMC.grad_huang1980_sampled
            import mlstatistics.HMC.normal_prior
            
            % Unpack the parameter vector
            ks            = Parameters(1:end-1)'; % 4 x 1
            log_var_noise = Parameters(end);
            
            % Unpack huang1980 results
            [dqs_,qs_] = grad_huang1980_sampled(ks, artery_interpolated, ts);
            
            % Compute the log likelihood and its gradient
            Sigma                     = sqrt(exp(log_var_noise)); % scalar
            Z                         = (1 - qs_'./qs')./Sigma; % 62 x 1
            loglik                    = sum(-log(qs'.*Sigma) - 0.5*log(2*pi) - 0.5*Z.^2); % scalar
            grad_loglik_kst           = dqs_*Z./Sigma; % 4 x 1
            grad_loglik_log_var_noise = sum(-.5 + .5*(Z.^2)); % scalar
            
            % Compute log priors and gradients
            [logprior_kst, grad_logprior_kst] = ...
                normal_prior(ks', mean_ks', sigma_ks');
            [logprior_log_var_noise, grad_logprior_log_var_noise] = ...
                normal_prior(log_var_noise, mean_log_var_noise, sigma_log_var_noise);
            logprior = logprior_kst + logprior_log_var_noise;
            
            % Return the log posterior and its gradient
            logpost                    = loglik + logprior; % scalar
            grad_logpost_kst           = grad_loglik_kst + grad_logprior_kst;
            grad_logpost_log_var_noise = grad_loglik_log_var_noise + grad_logprior_log_var_noise;
            grad_logpost               = [grad_logpost_kst; grad_logpost_log_var_noise]; % 5 x 1
        end
    end

	methods 
        function [MAPPars,finfo] = estimateMAP(this, varargin)
            [MAPPars,finfo] = estimateMAP(this.smp, varargin{:});
            assert(all(MAPPars(1:end-1) > 0), ...
                'Huang1980WithHMC.drawTunedSamples.MAPPars->%s', mat2str(MAPPars))
            fprintf('estimateMAP().MAPPars:  %s\n\n', mat2str(MAPPars))
            this.plot_MAP_iterations(finfo)
        end
        function mp = jitter_MAPPars(this)
            mp = this.MAPPars + this.jitter_scale .* randn(size(this.MAPPars));
            mp(1:end-1) = abs(mp(1:end-1)); % reflecting boundary conditions on jittered MAPPars
        end
        function this = build_recon_times(this)
            this.recon_times = this.recon_end_times;
            return
            
            this.recon_times = nan(size(this.recon_end_times));
            this.recon_times(1) = this.recon_end_times(1)/2;
            for it = 2:length(this.recon_end_times)
                this.recon_times(it) = this.recon_end_times(it-1) + ...
                    (this.recon_end_times(it) - this.recon_end_times(it-1))/2;
            end
        end
        function plot_model_results(this)
            qs = this.huang1980_sampled(this.results.Mean(1:4), this.artery_interpolated, this.recon_times);
            figure
            plot(this.recon_times, qs, ':o', this.recon_times, this.true_qs)
            title('mlkinetics.Huang1980WithHMC.plot\_model\_results()')
            xlabel('time / s')
            ylabel('activity / (kBq/mL)')
        end
        function g = rand_ks(this)
            g = abs([0.2 * rand() 0.3 * rand() 0.1 * rand() 5e-4 * rand()]);
        end
		  
 		function this = Huang1980WithHMC(varargin)
 			%% HUANG1980WITHHMC
            %  @param varargin for hmcSampler(logpdf, startpoint, varargin{:})
            
 			this = this@mlstatistics.HMC();
            
            import mlkinetics.Huang1980WithHMC.log_posterior
            
            tic
            this.artery_interpolated = readmatrix(this.csv_filename);
            this = this.build_recon_times();
            this.NumPredictors = 4;
            
            % Use these parameter values to create a normally distributed sample data
            % set at random values of the predictors.
            rng('default') %For reproducibility
            this.true_ks = this.rand_ks();
            this.true_qs = this.huang1980_sampled(this.true_ks, this.artery_interpolated, this.recon_times);
            this.true_qs = abs(this.true_qs .* (1 + this.true_sigma_noise*randn(size(this.true_qs))));
            this.true_qs(this.true_qs < this.WELL_BACKGROUND) = this.WELL_BACKGROUND;

            % Choose the means and standard deviations of the Gaussian priors.
            mean_ks = [0.1 0.1 0.1 1e-4];
            sigma_ks = mean_ks;
            mean_log_var_noise = log(this.true_sigma_noise^2);
            sigma_log_var_noise = 2;
            
            % Save a function |log_posterior| on the MATLAB(R) path that returns the
            % logarithm of the product of the prior and likelihood, and the gradient of
            % this logarithm.  Then, call the function with arguments to define the |logpdf|
            % input argument to the |hmcSampler| function.
            logpdf = @(Parameters) logPosterior( ...
                Parameters, this.recon_times', this.true_qs', this.artery_interpolated', ...
                ksPriorMean', ksPriorSigma', ...
                LogNoiseVarianceMean, LogNoiseVarianceSigma);
            
            % Define the initial point to start sampling from, and then call the
            % |hmcSampler| function to create the Hamiltonian sampler as a
            % |HamiltonianSampler| object. Display the sampler properties.
            startpoint = [this.rand_ks()'; log((this.true_sigma_noise * randn)^2)];
            this.smp = hmcSampler(logpdf, startpoint, varargin{:});            
            %this.smp.StepSize = 0.01; % speed up tuning
            this.smp.NumSteps = 20;   % speed up tuning
            fprintf('Huang1980WithHMC().smp:\n'); disp(this.smp)
            
            [this.MAPPars,this.fitinfo] = this.estimateMAP();
            this.jitter_scale = [sigma_ks'; sigma_log_var_noise];
            this = this.drawTunedSamples('NumChains', 4, 'Burnin', 500, 'NumSamples', 1000);
            this = this.diagnostics;
            fprintf('\n')
            fprintf('Huang1980WithHMC().results:\n\n'); disp(this.results)
            fprintf('true [ks(:) log(noise_sigma^2)]:  %s\n', ...
                mat2str([this.true_ks log(this.true_sigma_noise^2)]))
            this.plot_model_results()
            
            fprintf('Huang1980WithHMC().this:\n'); disp(this)
            toc
            this.finalize()            
            this.saveFigures()
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

