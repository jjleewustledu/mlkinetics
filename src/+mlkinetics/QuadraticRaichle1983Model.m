classdef QuadraticRaichle1983Model < handle & mlkinetics.QuadraticModel
    %% line1
    %  line2
    %  
    %  Created 06-Sep-2023 15:20:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        ho_ic
    end

    methods %% GET
        function g = get.ho_ic(this)
            if ~isempty(this.ho_ic_)
                g = copy(this.ho_ic_);
                return
            end
            this.ho_ic_ = this.scanner_kit_.do_make_activity_density();
            g = copy(this.ho_ic_);
        end
    end

    methods
        function mdl = build_model(~, obs, cbf)
            %% build_model 
            %  @param obs are numeric PET_{obs} := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF or similar flows in mL/hg/min.
            %  @returns mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('QuadraticNumeric.build_model ..........\n');
            mdl = fitnlm( ...
                ascolumn(obs), ...
                ascolumn(cbf), ...
                @mlkinetics.QuadraticModel.obsPetQuadraticModel, ...
                [1 1]);
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(obs), max(obs));
            if ~isempty(getenv('DEBUG'))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
        end
        function soln = build_solution(this)

            % check dynamic imaging

            % check & adjust input functions, esp. their timings and timing boundaries, 
            % to match dynamic imaging 

            obsPet = this.obsFromTac(this.measurement_, t0=this.t0, tF=this.tF);
            obsAif = this.obsFromAif(this.artery_interpolated_, this.canonical_f);
            this.modelA = this.build_model(obsAif, this.canonical_cbf);
            img = this.a1*obsPet.^2 + this.a2*obsPet; % cbf ~ mL/hg/min
            
            soln = copy(this.ho_ic.imagingFormat);
            soln.img = single(img);
            soln.fileprefix = strrep(this.ho_ic.fileprefix, "_trc-ho", "_cbf");
            soln = mlfourd.ImagingContext2(soln);
            this.product_ = soln; % fullfills mlkinetics.Model's builder design pattern
        end

        %% UTILITIES

        function t = tauObs(~)
            t = 60;
        end
        function t = timeStar(~)
            t = 0; % sec, per Martin's 1987 paper
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.QuadraticRaichle1983Model(varargin{:});
        end
    end

    %% PRIVATE

    properties (Access = private)
        ho_ic_
    end

    methods (Access = private)
        function this = QuadraticRaichle1983Model(varargin)
            this = this@mlkinetics.QuadraticModel(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
