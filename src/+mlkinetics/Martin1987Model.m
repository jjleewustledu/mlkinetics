classdef Martin1987Model < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 02-Aug-2023 16:23:14 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        dlicv_ic
    end

    methods %% GET
        function g = get.dlicv_ic(this)
            g = this.bids_med_.dlicv.ic;
        end
    end

    methods
        function v1_ = make_solution(this, varargin)
            %  Return v1_ in R^, mlfourd.ImagingContext2, without saving to filesystems.  
            
            scanPath = this.bids_med_.scanPath;
            ensuredir(scanPath);
            pwd0 = pushd(scanPath);
            
            msk = this.dlicv_ic;
            v1_ = msk.nifti;
            v1_.filepath = scanPath;
            obj = this.vsOnAtlas(tags=this.tags);
            v1_.fileprefix = obj.fileprefix;

            % solve Martin
            this.solver_ = this.solver_.solve();  

            % insert Martin solutions into fs
            v1_.img = this.v1('typ', 'single');
            v1_ = mlfourd.ImagingContext2(v1_);

            popd(pwd0);
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Martin1987Model(varargin{:});

            this.bids_med_ = this.bids_kit_.make_bids_med();

            [tac_,timesMid_,t0_,aif_] = this.scanner_kit_.mixTacAif( ...
                this.scanner_kit_, ...
                scanner=this.scanner_kit_.do_make_device(), ...
                arterial=this.input_func_kit_.do_make_device(), ...
                roi=this.dlicv_ic);
            fp = sprintf("%s_dt%s", stackstr(), datetime("now", InputFormat="yyyymmddHHMMSS")); 

            this.representation_ = mloxygen.DispersedMartin1987Model(varargin{:});
            this.measurement_ = tac_;
            this.solver_ = mloxygen.DispersedMartin1987Solver( ...
                'context', this, varargin{:});
        end
    end

    %% PRIVATE

    properties (Access = private)
        bids_med_
    end

    methods (Access = private)
        function this = Martin1987Model(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end

        function ks_ = ks(this, varargin)
            %% ks == v1
            %  @param 'typ' is char, understood by imagingType.            
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            k(1) = k1(this.strategy_, varargin{:});
             
            roibin = logical(this.roi);
            ks_ = copy(this.roi.fourdfp);
            ks_.img = zeros([size(this.roi) this.LENK]);
            for t = 1:length(k)
                img = zeros(size(this.roi), 'single');
                img(roibin) = k(t);
                ks_.img(:,:,:,t) = img;
            end
            ks_.fileprefix = this.sessionData.vsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            ks_ = imagingType(ipr.typ, ks_);
        end 
        function v1_ = v1(this, varargin)
            v1_ = this.ks(varargin{:});
        end 
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
