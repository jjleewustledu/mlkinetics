classdef (Abstract) QuadraticModel < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 17-Aug-2023 02:44:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        canonical_cbf = 8:2:110 % mL/hg/min
                                % not to exceed 110 per Cook's distance from buildQuadraticModel()
        modelA
        modelB12
        modelB34
    end

    properties (Dependent)
        a
        a1
        a2
        b
        b1
        b2
        b3
        b4

        alpha_decay
        canonical_f
    end

    methods %% GET
        function g = get.a(this)
            g = [this.a1 this.a2];
        end
        function g = get.a1(this)            
            g = this.modelA.Coefficients{1, 'Estimate'};
        end
        function g = get.a2(this)            
            g = this.modelA.Coefficients{2, 'Estimate'};
        end
        function g = get.b(this)
            g = [this.b1 this.b2 this.b3 this.b4];
        end
        function g = get.b1(this)            
            g = this.modelB12.Coefficients{1, 'Estimate'};
        end
        function g = get.b2(this)            
            g = this.modelB12.Coefficients{2, 'Estimate'};
        end
        function g = get.b3(this)            
            g = this.modelB34.Coefficients{1, 'Estimate'};
        end
        function g = get.b4(this)            
            g = this.modelB34.Coefficients{2, 'Estimate'};
        end

        function g = get.alpha_decay(~)
            g = mlpet.Radionuclides.decayConstantOf("15O");
        end 
        function g = get.canonical_f(this)
            g = mlkinetics.OxyMetabConversion.cbfToF1(this.canonical_cbf);
        end
    end

    methods
        function obs = obsFromAif(this, varargin)
            %% Cf. Videen 1987, Eq. 2.
            %  @param required aif is a vector containing arterial input, sampled at 1 Hz.
            %  @param required f is the vector of flows to model, expressed as Hz.
            %  @return obs is the RHS of Eq. 2, a scalar \int_0^T dt \text{tracer density}.
            
            ip = inputParser;
            addRequired(ip, 'aif', @isnumeric)
            addRequired(ip, 'f', @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            ipr.aif = asrow(ipr.aif);
            ipr.f = ascolumn(ipr.f);
            
            lam = mlkinetics.OxyMetabConversion.LAMBDA;
            alph = this.alpha_decay;  
            N = length(ipr.aif);
            M = length(ipr.f);
            times = 0:(N-1);
            rho = zeros(M, this.tF_-this.t0_+1);
            for r = 1:M
                rho_ = ipr.f(r)*conv(ipr.aif, exp(-(ipr.f(r)/lam + alph)*times));
                rho(r,:) = rho_(this.t0_+1:this.tF_+1);
            end

            obs = trapz(rho, 2); % \int dt
        end
        function obs = obsFromTac(this, varargin)
            %% Cf. Videen 1987, Eq. 2.
            %  @param required tac is numeric, containing scanner TAC in R^(3+1) with native time-frames.
            %  @param optional taus is the vector of sampling durations for native time-frames.
            %  @param optional t0 is the start time of observation in seconds.
            %  @param optional tF is the finish time of observation in seconds.
            %  @return obs is the RHS of Eq. 2, in R^3 := \int_0^T dt \text{tracer density}.            
            
            ip = inputParser;
            addRequired(ip, 'tac', @isnumeric)
            addParameter(ip, 'timesMid', this.timesMid_, @isnumeric)
            addParameter(ip, 't0', this.t0_, @isscalar)
            addParameter(ip, 'tF', this.tF_, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            assert(size(ipr.tac,4) == length(ipr.timesMid))

            if size(ipr.tac,4) < 10
                timesMore = linspace(ipr.timesMid(1), ipr.timesMid(end)); % N = 100
                ipr.tac = this.interpolate_img(ipr.tac, ipr.timesMid, timesMore);
            else
                timesMore = ipr.timesMid;
            end            
            window = ipr.t0 <= timesMore & timesMore <= ipr.tF;            
            obs = trapz(timesMore(window), ipr.tac(:,:,:,window), 4);
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function img = interpolate_img(~, img, timesMid, timesMore)
            sz = size(img);
            %tic
            [x,y,z,t] = ndgrid(1:sz(1), 1:sz(2), 1:sz(3), timesMid);
            [xq,yq,zq,tq] = ndgrid(1:sz(1), 1:sz(2), 1:sz(3), timesMore);
            img = interpn(x, y, z, t, img, xq, yq, zq, tq);
            %toc
        end
        function this = QuadraticModel(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    methods (Static, Access = protected)
        function obsPet = obsPetQuadraticModel(As, f)
            %% @return PET_{obs} ~ activity density from flow ~ 1/s.  See also Herscovitch 1985 & Videen 1987.
            
            obsPet = f.^2*As(1) + f*As(2);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
