classdef Huang1980SimulAnneal 
	%% HUANG1980SIMULANNEAL  

	%  $Revision$
 	%  was created 03-Jan-2020 17:45:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)        
 		aif
        cbv
        glc
        hct
        scanner
        
 		artery_interpolated
        recon_activities
        recon_times
        results
 	end

	methods 
        
        %% GET
        
        function g = get.aif(this)
            g = this.huang_.aif;
        end
        function g = get.cbv(this)
            g = this.huang_.cbv;
        end
        function g = get.glc(this)
            g = this.huang_.glc;
        end
        function g = get.hct(this)
            g = this.huang_.hct;
        end
        function g = get.scanner(this)
            g = this.huang_.scanner;
        end
        
        function g = get.artery_interpolated(this)
            g = this.huang_.artery_interpolated;
        end
        function g = get.recon_activities(this)
            g = this.huang_.recon_activities;
        end
        function g = get.recon_times(this)
            g = this.huang_.recon_times;
        end
        function g = get.results(this)
            g = this.results_;
        end
        
        %%
        
        function disp(this)            
            fprintf('\n')
            fprintf(class(this))
            disp(this.aif)
            disp(this.scanner)
            fprintf('        cbv: '); disp(this.cbv)
            fprintf('        glc: '); disp(this.glc)
            fprintf('        hct: '); disp(this.hct)
            fprintf('initial ks0: '); disp(this.results_.ks0)
            fprintf('est.     ks: '); disp(this.results_.ks)
            fprintf('        sse: '); disp(this.results_.sse)
            fprintf('   exitflag: '); disp(this.results_.exitflag)
            disp(this.results_.output)
            disp(this.results_.output.rngstate)
            disp(this.results_.output.temperature)
        end
        
        function plot(this)            
            figure
            plot(this.recon_times, qs0, '-+', ...
                 this.recon_times, this.huang_.huang1980_sampled(ks, ai, rt), ':o')
            legend('data', 'est.')
            xlabel('times / s')
            ylabel('activity / (Bq/mL)')
        end
        
        function results = simulanneal(this)            
            ai = this.artery_interpolated;
            rt = this.recon_times;
            qs0 = this.recon_activities;
            coef = [.2 .3 .1 5e-4] ;
            ks0 = coef * rand();
            ub = coef * 1e2;
            lb = coef / 1e2;
            options_fmincon = optimoptions('fmincon', ...
                'FunctionTolerance', 1e-9, ...
                'OptimalityTolerance', 1e-9);
            options = optimoptions('simulannealbnd', ...                
                'AnnealingFcn', 'annealingboltz', ...
                'FunctionTolerance', eps, ...
                'HybridFcn', {@fmincon, options_fmincon}, ...
                'InitialTemperature', 20, ...
                'ReannealInterval', 200, ...
                'TemperatureFcn', 'temperatureexp');            
                %'Display', 'diagnose', ...
                %'PlotFcns', {@saplotbestx,@saplotbestf,@saplotx,@saplotf,@saplotstopping,@saplottemperature} ...
            sigma0 = 1;
 			[ks,sse,exitflag,output] = simulannealbnd( ...
                @(ks_) this.huang_.huang1980_simulanneal_objective(ks_, this.cbv, ai, rt, qs0, sigma0), ...
                ks0, lb, ub, options);
            
            this.results_ = struct('ks0', ks0, 'ks', ks, 'sse', sse, 'exitflag', exitflag, 'output', output);
            results = this.results_;  
            disp(this)
            plot(this)
        end
		  
 		function this = Huang1980SimulAnneal(varargin)
 			%% HUANG1980SIMULANNEAL
 			%  @param for mlkinetics.Huang1980()

            this.huang_ = mlkinetics.Huang1980(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        huang_
        results_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

