classdef (Abstract) TracerKit < handle
    %% TRACERKIT provides factory methods 
    %  
    %  Created 09-Jun-2022 11:17:15 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties (Dependent)
        imagingContext
        taus
    end

    methods

        %% GET, SET

        function g = get.imagingContext(this)
            g = this.tracerData_.imagingContext;
        end
        function     set.imagingContext(this, s)
            this.tracerData_.imagingContext = s;
        end
        function g = get.taus(this)
            g = this.tracerData_.taus;
        end
        function     set.taus(this, s)
            this.tracerData_.taus = s;
        end

        %%

        function tra = make_tracer(~, imaging, taus)
            re = regexp(imaging.fileprefix, '\S+_trc-(?<tra>\w+)_\S+', 'names');
            if contains({'co', 'oc'}, lower(re.tra))
                tra = mloxygen.CarbonMonoxideKit.instance(imaging, taus);
            end
            if contains({'oo'}, lower(re.tra))
                tra = mloxygen.OxygenKit.instance(imaging, taus);
            end
            if contains({'ho'}, lower(re.tra))
                tra = mloxygen.WaterKit.instance(imaging, taus);
            end
            if contains({'18f-dg', 'fdg'}, lower(re.tra))
                tra = mlglucose.F18DeoxyGlucoseKit.instance(imaging, taus);
            end
            if contains({'11c-glc', 'glc'}, lower(re.tra))
                tra = mlglucose.C11GlucoseKit.instance(imaging, taus);
            end
        end
    end

    %% PROTECTED

    properties (Access = protected)
        tracerData_
    end

    methods (Access = protected)
        function this = TracerKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
