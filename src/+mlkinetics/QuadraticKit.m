classdef QuadraticKit < handle
    %% QUADRATICKIT supports the abstract factory design pattern for implementing quadratic 
    %  parameterization of kinetic rates.  See also mlkinetics.KineticsKit.  See also papers by Videen, Herscovitch. 
    %  
    %  Created 04-Apr-2023 12:34:56 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 9.14.0.2206163 (R2023a) for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function cbf_ = buildCbf(this)
            %% BUILDCBF
            %  @return cbf on filesystem.

            pwd0 = pushd(this.client_.immediator.subjectPath);
            fs_ = this.buildFs();
            cbf_ = this.client_.fs2cbf(fs_);
            cbf_.save() % save ImagingContext2            
            popd(pwd0);
        end
        function cbv_ = buildCbv(this)
            %% BUILDCBV
            %  @return cbf on filesystem.
            
            pwd0 = pushd(this.client_.immediator.subjectPath);            
            vs_ = this.buildVs();
            cbv_ = this.client_.vs2cbv(vs_);
            cbv_.save() % save ImagingContext2
            popd(pwd0);
        end
        function [cmro2_,oef_] = buildCmro2(this)
            %% BUILDCMRO2
            %  @return cmro2, oef on filesystem.
            
            pwd0 = pushd(this.client_.immediator.subjectPath);             
            os_ = this.buildOs();
            cbf_ = this.client_.cbfOnAtlas( ...
                'typ', 'mlfourd.ImagingContext2', ...
                'dateonly', false, ...
                'tags', [this.client_.blurTag this.client_.regionTag]);
            [cmro2_,oef_] = this.client_.os2cmro2(os_, cbf_, this.client_.model);
            cmro2_ = this.client_.applyBrainMask(cmro2_);
            cmro2_.save() % save ImagingContext2
            oef_ = this.client_.applyBrainMask(oef_);
            oef_.save()      
            popd(pwd0);
        end
        function fs_ = buildFs(this)
            %% BUILDFS
            %  @return fs in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            
            import mlkinetics.QuadraticNumericRaichle1983
            
            ensuredir(this.client_.scanPath);
            pwd0 = pushd(this.client_.scanPath);  
                                    
            icv = this.client_.dlicv();
            devkit = mlpet.ScannerKit.createFromSession(this.client_.immediator);             
            scanner = devkit.buildScannerDevice();
            scannerBrain = scanner.volumeAveraged(icv);
            arterial = this.client_.buildAif(devkit, scanner, scannerBrain);
            
            fs_ = icv.nifti;
            fs_.filepath = this.client_.scanPath;
            ic = this.client_.fsOnAtlas(tags=this.client_.tags);
            fs_.fileprefix = ic.fileprefix;

            % solve Raichle
            fprintf('%s\n', datetime("now"))
            fprintf('starting mlraichle.QuadraticAerobicGlycolysisKit.buildFs\n')
            raichle = QuadraticNumericRaichle1983.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', icv);  
            raichle = raichle.solve();
            this.client_.model = raichle;

            % insert Raichle solutions into fs
            fs_.img = raichle.fs('typ', 'single');
                
            fs_ = mlfourd.ImagingContext2(fs_);
            popd(pwd0);
        end 
        function os_ = buildOs(this)
            %% BUILDOS
            %  @return os in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
                    
            import mlkinetics.QuadraticNumericMintun1984
            
            ensuredir(this.client_.scanPath);
            pwd0 = pushd(this.client_.scanPath);  
                                    
            icv = this.client_.dlicv();
            devkit = mlpet.ScannerKit.createFromSession(this.client_.immediator);            
            scanner = devkit.buildScannerDevice(); 
            scannerBrain = scanner.volumeAveraged(icv); 
            arterial = this.client_.buildAif(devkit, scanner, scannerBrain);
            
            os_ = icv.nifti;
            os_.filepath = this.client_.scanPath;
            ic = this.client_.osOnAtlas(tags=this.client_.tags);
            os_.fileprefix = ic.fileprefix;

            % solve Mintun
            fprintf('%s\n', datetime("now"))
            fprintf('starting mlraichle.QuadraticAerobicGlycolysisKit.buildOs\n')
            mintun = QuadraticNumericMintun1984.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', icv);  
            mintun = mintun.solve();
            this.client_.model = mintun;

            % insert Raichle solutions into fs
            os_.img = mintun.os('typ', 'single');

            os_ = mlfourd.ImagingContext2(os_);
            popd(pwd0);
        end
        function vs_ = buildVs(this)
            %% BUILDVS
            %  @return vs_ in R^3 as mlfourd.ImagingContext2, without saving to filesystems.  
            
            import mlkinetics.QuadraticNumericMartin1987
            
            ensuredir(this.client_.scanPath);
            pwd0 = pushd(this.client_.scanPath);                                    
            
            icv = this.client_.dlicv();
            devkit = mlpet.ScannerKit.createFromSession(this.client_.immediator);             
            scanner = devkit.buildScannerDevice();
            scannerBrain = scanner.volumeAveraged(icv);
            arterial = this.client_.buildAif(devkit, scanner, scannerBrain);
            
            vs_ = icv.nifti;
            vs_.filepath = this.client_.scanPath;
            obj = this.client_.vsOnAtlas(tags=this.client_.tags);
            vs_.fileprefix = obj.fileprefix;

            % solve Martin
            fprintf('%s\n', datetime("now"))
            fprintf('starting mlraiche.QuadraticAerobicGlycolysisKit.buildVs\n')
            martin = QuadraticNumericMartin1987.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', icv);
            martin = martin.solve();  
            this.client_.model = martin;

            % insert Martin solutions into fs
            vs_.img = martin.vs('typ', 'single');

            vs_ = mlfourd.ImagingContext2(vs_);
            popd(pwd0);
        end
        function this = call(this, request)
            arguments
                this mlkinetics.QuadraticKit
                request {mustBeTextScalar}
            end
            switch lower(request)
                case {'cbf', 'fs'}
                    this.buildCbf();
                case {'cbv', 'vs'}
                    this.buildCbv();
                case {'cmro2', 'os'}
                    this.buildCmro2();
                case 'all'
                    this.buildCbf();
                    this.buildCbv();
                    this.buildCmro2();
                otherwise
                    error('mlkinetics:ValueError', 'QuadraticKit.call.request -> %s', request)
            end
        end

        function this = QuadraticKit(client)
            arguments
                client {mustBeNonempty} = []
            end
            this.client_ = client;
        end
    end

    %% PROTECTED

    properties (Access = protected)
        client_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
