classdef (Abstract) InputFuncKit < handle & mlsystem.IHandle
    %% is an abstract factory design pattern for input functions and reference regions.
    %  It is an extensible factory making using of the factory method pattern (cf. GoF pp. 90-91, 107). 
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  
    %  Created 02-May-2023 14:24:08 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.

    properties (Abstract)
        decayCorrected
    end

    methods (Abstract)

        %% make related products, with specialty relationships specified by the factory

        do_make_activity(this)
        do_make_activity_density(this)
        do_make_device(this)
        do_make_input_func(this)
    end

    properties (Dependent)
        recovery_coeff % multiplies input function
    end

    methods %% GET
        function g = get.recovery_coeff(this)
            g = this.recovery_coeff_;
        end
    end

    methods
        function decayCorrect(this)
            %if ~isempty(this.input_func_ic_)
            %    error("mlkinetics:NotImplementedError", "InputFuncKit.decayCorrect")
            %end
            if isempty(this.device_)
                do_make_device(this);
            end
            decayCorrect(this.device_);
        end
        function decayUncorrect(this)
            %if ~isempty(this.input_func_ic_)
            %    error("mlkinetics:NotImplementedError", "InputFuncKit.decayUncorrect")
            %end
            if isempty(this.device_)
                do_make_device(this);
            end
            decayUncorrect(this.device_);
        end
        
        function h = do_make_plot(this)
            h = figure;
            img = asrow(this.input_func_ic_.imagingFormat.img);
            try
                timesMid = asrow(this.input_func_ic_.json_metadata.timesMid);
                xl = "times (s)";
            catch ME
                handwarning(ME)
                timesMid = 1:length(img);
                xl = "time frame";
            end
            plot(timesMid, img, ":o")
            xlabel(xl);
            ylabel("activity density (Bq/mL)");
            title(sprintf("%s: \n%s", stackstr(3), this.input_func_ic_.fileprefix), interprete="none");
            fontsize(gcf, scale=1.2)
            saveFigure2(h, this.input_func_ic_.fqfp, closeFigure=false)
        end
    end
    
    methods (Static)
        
        %% convenience create-methods for clients

        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
                opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty}
                opts.input_func_tags string
                opts.input_func_fqfn string
                opts.recovery_coeff double = 1
            end
            copts = namedargs2cell(opts);

            if any(contains(opts.input_func_tags, "twilite", IgnoreCase=true))
                this = mlswisstrace.TwiliteKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, "caprac", IgnoreCase=true))
                this = mlcapintec.CapracKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, "hidex", IgnoreCase=true))
                this = mlhidex.HidexKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, "beckman", IgnoreCase=true))
                this = mlpet.BeckmanKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, "fung", IgnoreCase=true))
                this = mlkinetics.FungIdifKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, "mip", IgnoreCase=true))
                this = mlkinetics.MipIdifKit.instance(copts{:});
                return
            end
            if any(contains(opts.input_func_tags, ["nifti","imaging_format","imaging_context"], IgnoreCase=true))
                this = mlkinetics.NiftiInputFuncKit.instance(copts{:});
                return
            end
        end
        function ic = estimate_recovery_coeff(opts)
            arguments
                opts.scan_path {mustBeFolder}
                opts.scan_fqfn {mustBeFile}
                opts.idif_fqfn {mustBeFile}
                opts.tracer_tags {mustBeTextScalar}
                opts.model_tags {mustBeTextScalar}
            end

            import mlkinetics.*
            bk = BidsKit.create( ...
                bids_tags="ccir1211", bids_fqfn=opts.scan_fqfn);
            tk = TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=datetime(2022,2,1, TimeZone="local"), ...
                tracer_tags=opts.tracer_tags, ...
                counter_tags="caprac");
            sk = ScannerKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_tags="vision");
            ifk = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="nifti", ...
                input_func_fqfn=opts.idif_fqfn);
            ifk_art = InputFuncKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, ...
                input_func_tags="twilite");
            pk = [];

            % make two solutions:  idif & twilite
            mk = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk, parc_kit=pk, ...
                data=struct([]), ...
                model_tags=opts.model_tags);
            soln = mk.make_solution();
            mk_art = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk_art, parc_kit=pk, ...
                data=struct([]), ...
                model_tags=opts.model_tags);
            soln_art = mk_art.make_solution();

            % selection mask
            med = bk.do_make_med();
            select = logical(med.dlicv_ic.imagingFormat.img);

            % select recovery coeff from 3D
            ic = soln_art./soln;
            ic.fileprefix = bk.sprintf()+"_"+stackstr();
            ic.scrubNanInf()
            rc = ic.imagingFormat.img(select);
            
            fprintf("%s: recovery coeff. = %g +/- %g", ...
                stackstr(), mean(rc, "omitnan"), std(rc, 0, "omitnan"))
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_
        device_
        input_func_fqfn_
        input_func_ic_
        input_func_tags_
        recovery_coeff_
        scanner_kit_
        tracer_kit_        
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.scanner_kit_)
                that.scanner_kit_ = copy(this.scanner_kit_); end
            if ~isempty(this.tracer_kit_)
                that.tracer_kit_ = copy(this.tracer_kit_); end
        end
        function install_input_func(this, opts)
            arguments
                this mlkinetics.InputFuncKit
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
                opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty}
                opts.input_func_tags string = ""
                opts.input_func_fqfn string = ""
                opts.recovery_coeff double = 1
            end

            for f = asrow(fields(opts))
                if ~isempty(opts.(f{1}))
                    this.(strcat(f{1}, "_")) = opts.(f{1});
                end
            end
        end
        function this = InputFuncKit()
        end
    end    

    %% HIDDEN
    
    methods (Hidden)

        %% legacy synonyms

        function a = activity(this)
            a = this.do_make_activity();
        end
        function a = activityDensity(this)
            a = this.do_make_activity_density();
        end
    end

    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end