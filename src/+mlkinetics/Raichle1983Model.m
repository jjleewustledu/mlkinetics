classdef Raichle1983Model < handle & mlkinetics.Model
    %% line1
    %  line2
    %  
    %  Created 13-Jun-2023 22:30:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2254940 (R2023a) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        fileprefix
    end

    methods %% GET
        function g = get.fileprefix(this)
            bids_med = this.bids_kit_.make_bids_med();
            ic = bids_med.imagingContext;
            g = ic.fileprefix;
            assert(contains(g, "_pet"))
            g = strrep(g, "_pet", "_raichle1983model");
        end
    end

    methods
        function initialize(this, varargin)
        end
        function ks = make_ks(this)

            bids_med = this.bids_kit_.make_bids_med();

            ensuredir(bids_med.scanPath);
            pwd0 = pushd(bids_med.scanPath);
                                    
            dlicv = bids_med.dlicv_ic();
            devkit = mlpet.ScannerKit.createFromSession(this.immediator);             
            scanner = this.scanner_kit_.do_make_device();
            arterial = this.input_func_kit_.do_make_activity_density(); 
            
            ks_ = dlicv.nifti;
            ks_.filepath = bids_med.scanPath;
            ks_.fileprefix = this.fileprefix;

            % solve Raichle
            raichle = QuadraticNumericRaichle1983.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', dlicv);  
            raichle = raichle.solve();

            % insert Raichle solutions into fs
            ks_.img = raichle.fs('typ', 'single');
                
            ks = mlfourd.ImagingContext2(ks_);

            popd(pwd0);
        end
    end

    methods (Static)
        function this = create(varargin)
            this = mlkinetics.Raichle1983Model(varargin{:});
        end
    end

    %% PROTECTED

    properties (Access = protected)
    end

    methods (Access = protected)
        function this = Raichle1983Model(varargin)
            this = this@mlkinetics.Model(varargin{:});     
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
