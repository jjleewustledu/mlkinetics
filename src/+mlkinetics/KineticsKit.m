classdef (Abstract) KineticsKit < handle
    %% KINETICSKIT is an abstract factory design pattern providing an interface for tracer kinetics.
    %  It provides interfaces for varieties of imaging data, input functions, kinetic models, and
    %  quality-assurance measures.  It requires configuration with concrete choices for BIDS 
    %  (https://bids-specification.readthedocs.io/en/stable/), tracers, scanners, input function methods, 
    %  and kinetic models with specified inference methods.  
    %
    %  See also:  mlkinetics.BidsKit, mlkinetics.TracerKit, mlkinetics.ScannerKit, 
    %             mlkinetics.InputFunctionKit, mlkinetics.KineticModelKit.
    %  
    %  Created 09-Jun-2022 10:25:54 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods (Abstract)
        make_bids(this)
        make_study(this, bids)
        make_subject(this, study)
        make_session(this, subject)
        make_tracer(this)
        make_scanner(this, client, session, tracer)
        make_input_function(this, varargin)
        make_model(this)
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
