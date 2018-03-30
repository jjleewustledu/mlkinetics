classdef BlomqvistKinetics 
	%% BLOMQVISTKINETICS 
    %  See also:  J. Cereb. Blood Flow & Metab. 4:629-632 1984.

	%  $Revision$
 	%  was created 16-Feb-2018 19:05:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)        
        LC = 0.64 % Powers, et al., JCBFM 31(5) 1223-1228, 2011.
        %LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
    end

    methods (Static)
        function qT  = qpet(Ca, qt, t, k1, k2, k3, v1)
            %  @param rows
            %  @return rows
            
            % test:
            % t = 0:9; Aa = exp(-t/3); qt = 1 - exp(-t/3); 
            % qT = BlomqvistKinetics.qpet(Aa, [], 1, 1, 1, qt, t, 1) \sim t;
            % plot(t,Aa,t,qt)
            
            % disable for speed:
            %%assert(isrow(Ca) && isrow(qt) && isrow(t));
            %%assert(all(size(Ca) == size(qt)) && ...
            %%       all(size(qt) == size(t)));
            
            dt     = mlkinetics.BlomqvistKinetics.dt(t);
            qT     = zeros(size(qt));            
            Ca_dt_ = v1*Ca .* dt;
            qt_dt_ = qt    .* dt;
            for i = 1:length(qt)
                qT(i) = k1*trapz(Ca_dt_(1:i), 2) + ...
                        k1*k3*trapz(cumtrapz(Ca_dt_(1:i), 2).*dt(1:i), 2) - ...
                       (k2 + k3)*trapz(qt_dt_(1:i), 2);
            end
        end
        function col = Acol1(Ca, t, v1)
            %  @param rows
            %  @return col
            
            % disable for speed:
            %%assert(isrow(Ca) && isrow(t) && isscalar(v1));
            
            Ca_dt_ = v1 * Ca .* mlkinetics.BlomqvistKinetics.dt(t);
            col = zeros(length(t), 1);
            for i = 1:length(t)
                col(i) = trapz(Ca_dt_(1:i), 2);
            end            
            % col = ensureColVector(col);
        end
        function col = Acol2(Ca, t, v1)
            %  @param rows
            %  @return col
            
            % disable for speed:
            %%assert(isrow(Ca) && isrow(t) && isscalar(v1));
            
            dt = mlkinetics.BlomqvistKinetics.dt(t);
            Ca_dt_ = v1 * Ca .* dt;
            col = zeros(length(t), 1);
            for i = 1:length(t)
                col(i) = trapz(cumtrapz(Ca_dt_(1:i), 2).*dt(1:i), 2);
            end
            % col = ensureColVector(col);
        end
        function col = Acol3(qt, t)
            %  @param rows
            %  @return col
            
            % disable for speed:
            %%assert(isrow(qt) && isrow(t));
            
            qt_dt_ = qt .* mlkinetics.BlomqvistKinetics.dt(t);
            col = zeros(length(t), 1);
            for i = 1:length(t)
                col(i) = -trapz(qt_dt_(1:i), 2);
            end            
            % col = ensureColVector(col);
        end
        function tau = dt(t)
            tau = t(2:end) - t(1:end-1);
            tau = [tau tau(end)];
        end
        function Cp  = wb2plasma(Cwb, hct, t)
            if (hct > 1)
                hct = hct/100;
            end
            import mlkinetics.BlomqvistKinetics.*;
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
                            img(x,y,z) = this.buildCmrglcVoxel([x y z]);
                        end
                    end
                end
            end
            img = img * this.glc_ / this.LC;
            warning('on', 'optimlib:lsqlin:WillRunDiffAlg');
        end
        function vox  = buildCmrglcVoxel(this, xvec)
            %% BUILDCMRGLCVoxel solves A^T A \kappa = A^T q(T) for rates in \kappa given partial sums of 
            %  activities q(T) and A := Blomqvist's equation 8.
            
            import mlkinetics.*;
            rng_s = this.scanner_.index0:this.scanner_.indexF;
            t     = this.scanner_.times(rng_s);
            qT    = ensureRowVector(squeeze(this.scanner_.specificActivity(xvec(1),xvec(2),xvec(3),rng_s)));
            
            v1 = 0.01 * this.cbv_.img(xvec(1), xvec(2), xvec(3));            
            A  = [this.Acol1(this.Cp_,t,v1) this.Acol2(this.Cp_,t,v1) this.Acol3(qT,t)];
            
            opts = optimset('TolX', 1.e-2);
            lb_ = ([1e-4 1e-8 1e-4]/100)';
            ub_ = ([1e-2 1e-4 1e-2]*100)';
            kappa = lsqlin(A, qT', [], [], [], [], lb_, ub_, [], opts); 
            % kappa = lsqnonneg(A, qT', opts);            

            vox = (kappa(2)/kappa(3));
        end
        function this = buildKinetics(this, qt, qT, ks0) %#ok<INUSD>
            %% BUILDMODELCBF 
            %  @param qt are numeric.
            %  @param qT are numeric.
            %  @param ks0 are initial estimates of rates for the kinetics.
            %  @returns this with this.product := mdl.  ks are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            error('mlkinetics:notImplemented', 'BlomqvistKinetics.buildKinetics');
            
            fprintf('BlomqvistKinetics.buildKinetics ..........\n'); %#ok<UNRCH>
            mdl = fitnlm(ensureColVector(qt), ensureColVector(qT), @mlkinetics.BlomqvistKinetics.qpet, ks0);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(qt), max(qt));
            plotResiduals(mdl);
            plotDiagnostics(mdl, 'cookd');
            plotSlice(mdl);
            this.product_ = mdl;
        end
		  
 		function this = BlomqvistKinetics(varargin)
 			%% BLOMQVISTKINETICS
 			%  Usage:  this = BlomqvistKinetics()

 			ip = inputParser;
            addParameter(ip, 'aif',     [], @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'cbv',     [], @(x) isa(x, 'mlfourd.INIfTI'));
            addParameter(ip, 'glc',     [], @isscalar);
            addParameter(ip, 'hct',     [], @isscalar);
            parse(ip, varargin{:});            
            this.aif_     = ip.Results.aif;
            this.scanner_ = ip.Results.scanner;
            this.cbv_     = ip.Results.cbv;
            this.glc_     = ip.Results.glc;
            this.hct_     = ip.Results.hct;
            
            rng_s    = this.scanner_.index0:this.scanner_.indexF;
            t        = this.scanner_.times(rng_s);
            rng_a    = this.aif_.index0:this.aif_.indexF;
            Cwb      = pchip([0 this.aif_.times(rng_a)], [0 this.aif_.specificActivity(rng_a)], t);
            this.Cp_ = this.wb2plasma(Cwb, this.hct_, t);
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

