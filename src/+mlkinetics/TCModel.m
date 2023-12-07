classdef (Abstract) TCModel < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 11-Oct-2023 01:33:12 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 23.2.0.2380103 (R2023b) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Abstract, Constant)
        ks_names
    end

    methods (Abstract)
        sampled(this)
    end

    properties
        Data
        LENK
        map
    end

    properties (Dependent)
        raichleks_ic
        martinv1_ic
    end

    methods %% GET, SET
        function g = get.raichleks_ic(this)
            if isfield(this.data, "raichleks_ic")
                g = this.data.raichleks_ic;
                return
            end
            if isfield(this.data, "cbf_ic")
                g = this.data.cbf_ic;
                g = mlkinetics.OxyMetabConversion.f1ToCbf(g);
                return
            end
            g = [];
        end
        function g = get.martinv1_ic(this)
            if isfield(this.data, "martinv1_ic")
                g = this.data.martinv1_ic;
                return
            end
            if isfield(this.data, "cbv_ic")
                g = this.data.cbv_ic;
                g = mlkinetics.OxyMetabConversion.cbvToV1(g);
                return
            end
            g = [];
        end
    end

    methods
        function s = fqfp(this, opts)
            arguments
                this mlkinetics.TCModel
                opts.tag {mustBeTextScalar} = "ks"
            end

            s = this.product.fqfp;
            re = regexp(s, "\S+_(?<trc>trc-\w+)_\S+", "names");
            strrep(s, re.trc, opts.tag)
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function this = TCModel(varargin)
            this = this@mlkinetics.Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
