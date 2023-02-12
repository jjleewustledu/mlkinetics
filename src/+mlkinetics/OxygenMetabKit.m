classdef (Sealed) OxygenMetabKit < handle & mlkinetics.KineticsKit
    %% OXYGENMETABKIT is a concrete factory from an abstract factory design pattern.
    %  
    %  Created 09-Jun-2022 14:27:36 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods (Static)
        function this = instance(varargin)
            %% INSTANCE
            %  @param optional qualifier is char \in {'initialize' ''}
            
            ip = inputParser;
            addOptional(ip, 'qualifier', '', @ischar)
            parse(ip, varargin{:})
            
            persistent uniqueInstance
            if (strcmp(ip.Results.qualifier, 'initialize'))
                uniqueInstance = [];
            end          
            if (isempty(uniqueInstance))
                this = mlkinetics.OxygenMetabKit();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end

    methods
        function make_bids(this)
        end
        function make_study(this, bids)
        end
        function make_subject(this, study)
        end
        function make_session(this, subject)
        end
        function tra = make_tracer(this, imaging, taus)
            kit = mlkinetics.TracerKit();
            tra = kit.make_tracer(imaging, taus);
        end
        function sca = make_scanner(this, client, session, tracer)
            kit = mlkinetics.ScannerKit2();
            sca = kit.make_scanner(client, session, tracer);
        end
        function aif = make_input_function(this, client, varargin)
            kit = mlkinetics.InputFunctionKit();
            aif = kit.make_input_function(client, varargin{:});
        end
        function mdl = make_model(this, client, varargin)
            kit = mlkinetics.KineticsModelKit();
            mdl = kit.make_model(client, varargin{:})
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = OxygenMetabKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
