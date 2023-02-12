classdef (Abstract) ScannerKit2 < handle
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 13:51:38 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        client
        session
        tracer
    end

    methods (Abstract)
        dev = make_scanner_device(this)
        dev = make_sampling_device(this)
        dev = make_counting_device(this)
        dat = make_rad_measurements(this)
    end

    methods
        function sca = make_scanner(this, client, session, tracer)
            if isa(client, 'mlvg.Ccir559754')
                sca = mlsiemens.BiographMMRKit2.instance();
                sca.client = client;
                sca.session = session;
                sca.tracer = tracer;
            end
            if isa(client, 'mlvg.Ccir993')
                sca = mlsiemens.BiographMMRKit2.instance();
                sca.client = client;
                sca.session = session;
                sca.tracer = tracer;
            end
            if isa(client, 'mlvg.Ccir1211')
                sca = mlsiemens.BiographVisionKit2.instance();
                sca.client = client;
                sca.session = session;
                sca.tracer = tracer;
            end
        end

        function this = ScannerKit2()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
