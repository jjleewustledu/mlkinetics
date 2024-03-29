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
        hct % for TwiliteKit
        model_kind 
        recovery_coeff % multiplies input function
    end

    methods %% GET
        function g = get.hct(this)
            if isempty(this.device_)
                do_make_device(this);
            end
            g = this.device_.hct;
        end
        function     set.hct(this, s)
            if isempty(this.device_)
                do_make_device(this);
            end
            this.device_.hct = s;
        end
        function g = get.model_kind(this)
            if isempty(this.device_)
                do_make_device(this);
            end
            g = this.device_.model_kind;
        end
        function     set.model_kind(this, s)
            if isempty(this.device_)
                do_make_device(this);
            end
            this.device_.model_kind = s;
        end
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
            if isempty(this.input_func_ic_)
                this.do_make_activity_density()
            end
            img = asrow(this.input_func_ic_.imagingFormat.img);
            try
                timesMid = asrow(this.input_func_ic_.json_metadata.timesMid);
                xl = "times (s)";
            catch ME
                handwarning(ME)
                timesMid = 1:length(img);
                xl = "time frame";
            end
            N = min(length(timesMid), length(img));
            plot(timesMid(1:N), img(1:N), ":o")
            xlabel(xl);
            ylabel("activity density (Bq/mL)");
            title(sprintf("%s: \n%s", stackstr(3), this.input_func_ic_.fileprefix), interprete="none");
            fontsize(gcf, scale=1.2)
            saveFigure2(h, this.input_func_ic_.fqfp, closeFigure=false)
        end
        function save(this)
            if isempty(this.input_func_ic_)
                this.do_make_activity_density()
            end
            assert(~isempty(this.input_func_ic_))
            this.input_func_ic_.save();
        end
        function saveas(this, varargin)
            if isempty(this.input_func_ic_)
                this.do_make_activity_density()
            end
            assert(~isempty(this.input_func_ic_))
            this.input_func_ic_.saveas(varargin{:});
        end
    end
    
    methods (Static)
        
        %% convenience create-methods for clients

        function this = create_from_tags(opts)
            %% Creates InputFuncKit instance from tags and input func. specifiers.
            % Args:
            % opts.bids_fqfn {mustBeFile}
            % opts.bids_tags {mustBeTextScalar}
            % opts.ref_source_props = datetime(2022,2,1, TimeZone="local")
            % opts.counter_tags {mustBeTextScalar} = "caprac"
            % opts.scanner_tags {mustBeTextScalar}
            % opts.input_func_tags {mustBeTextScalar}
            % opts.input_func_fqfn {mustBeTextScalar} = ""       

            arguments
                opts.bids_fqfn {mustBeFile}
                opts.bids_tags {mustBeTextScalar}
                opts.ref_source_props = datetime(2022,2,1, TimeZone="local")
                opts.tracer_tags {mustBeTextScalar}
                opts.counter_tags {mustBeTextScalar} = "caprac"
                opts.scanner_tags {mustBeTextScalar}
                opts.input_func_tags {mustBeTextScalar}
                opts.input_func_fqfn {mustBeTextScalar} = ""
                opts.hct {mustBeNumeric} = 44.5
            end

            bk = mlkinetics.BidsKit.create( ...
                bids_fqfn=opts.bids_fqfn, ...
                bids_tags=opts.bids_tags);            
            tk = mlkinetics.TracerKit.create( ...
                bids_kit=bk, ...
                ref_source_props=opts.ref_source_props, ...
                tracer_tags=opts.tracer_tags, ...
                counter_tags=opts.counter_tags);
            sk = mlkinetics.ScannerKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_tags=opts.scanner_tags);
            this = mlkinetics.InputFuncKit.create( ...
                bids_kit=bk, ...
                tracer_kit=tk, ...
                scanner_kit=sk, ...
                input_func_tags=opts.input_func_tags, ...
                input_func_fqfn=opts.input_func_fqfn, ...
                hct=opts.hct);
        end
        function this = create(opts)
            %% Creates InputFuncKit instance from existing kits and input func. specifiers. 
            % Args:
            % opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
            % opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
            % opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty}
            % opts.input_func_tags string % may contain {"twilite", "caprac", "fung", "mip", "nifti", "*bolus"}
            % opts.input_func_fqfn string
            % opts.recovery_coeff double = 1      
            % opts.referenceDev = [], for time-aligning bolus inflow of input func

            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
                opts.scanner_kit mlkinetics.ScannerKit {mustBeNonempty}
                opts.input_func_tags string
                opts.input_func_fqfn string
                opts.recovery_coeff double = 1
                opts.referenceDev = []
                opts.hct double = 44.5
            end
            if isempty(opts.referenceDev)
                try
                    opts.referenceDev = opts.scanner_kit.do_make_device();
                catch ME
                    handwarning(ME)
                end
            end
            opts = mlkinetics.InputFuncKit.parse_model(opts);
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
                data=struct(), ...
                model_tags=opts.model_tags);
            soln = mk.make_solution();
            mk_art = ModelKit.create( ...
                bids_kit=bk, tracer_kit=tk, scanner_kit=sk, input_func_kit=ifk_art, parc_kit=pk, ...
                data=struct(), ...
                model_tags=opts.model_tags);
            soln_art = mk_art.make_solution();

            % selection mask
            med = bk.do_make_med();
            selected = logical(med.dlicv_ic.imagingFormat.img);

            % selected recovery coeff from 3D
            ic = soln_art./soln;
            ic.fileprefix = bk.sprintf()+"_"+stackstr();
            ic.scrubNanInf()
            rc = ic.imagingFormat.img(selected);
            
            fprintf("%s: recovery coeff. = %g +/- %g", ...
                stackstr(), mean(rc, "omitnan"), std(rc, 0, "omitnan"))
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_
        device_
        hct_ 
        input_func_fqfn_
        input_func_ic_
        input_func_tags_
        model_kind_
        recovery_coeff_
        referenceDev_
        scanner_kit_
        tracer_kit_        
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.device_)
                that.device_ = copy(this.device_); end
            if ~isempty(this.scanner_kit_)
                that.scanner_kit_ = copy(this.scanner_kit_); end
            if ~isempty(this.referenceDev_)
                that.referenceDev_ = copy(this.referenceDev_); end
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
                opts.referenceDev = []
                opts.hct double = 44.5
                opts.model_kind {mustBeTextScalar} = "3bolus"
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

    %% PRIVATE

    methods (Static, Access = private)
        function opts = parse_model(opts)
            if ~contains(opts.input_func_tags, "twilite", IgnoreCase=true) && ...
                    ~contains(opts.input_func_tags, "mip", IgnoreCase=true)
                return
            end
            if contains(opts.input_func_tags, "4bolus", IgnoreCase=true)
                opts.model_kind = "4bolus";
            end
            if contains(opts.input_func_tags, "3bolus", IgnoreCase=true)
                opts.model_kind = "3bolus";
            end
            if contains(opts.input_func_tags, "2bolus", IgnoreCase=true)
                opts.model_kind = "2bolus";
            end
            if contains(opts.input_func_tags, "1bolus", IgnoreCase=true)
                opts.model_kind = "1bolus";
            end
            if contains(opts.input_func_tags, "nomodel", IgnoreCase=true)
                opts.model_kind = "nomodel";
            end
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
