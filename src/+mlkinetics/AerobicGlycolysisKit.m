classdef (Sealed) AerobicGlycolysisKit < handle & mlkinetics.KineticsKit
    %% AEROBICGLYCOLYSISKIT is a concrete factory from an abstract factory design pattern.
    %  
    %  Created 09-Jun-2022 14:28:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
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
                this = mlkinetics.AerobicGlycolysisKit();
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
        function make_tracer(this, session)
        end
        function make_scanner(this, session, tracer)
        end
        function make_input_function(this, varargin)
        end
        function make_model(this)
        end
    end

    %% PRIVATE

    methods (Access = private)
        function this = AerobicGlycolysisKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
