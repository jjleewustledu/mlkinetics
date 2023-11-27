classdef (Abstract) KineticsKit < handle & mlsystem.IHandle
    %% KINETICSKIT is an abstract factory design pattern providing an interface for tracer kinetics.
    %  It is an extensible factory making using of the factory method pattern (cf. GoF pp. 90-91, 107). 
    %  It makes a family of related products.  Clients may use convenience create-methods to create related products. 
    %  It requires configuration with concrete choices for BIDS (https://bids-specification.readthedocs.io/en/stable/), 
    %  tracers, scanners, input functions, parcellations, and models.   
    %
    %  See also specialized abstract factories for choices of:  mlkinetics.BidsKit, mlkinetics.TracerKit, 
    %  mlkinetics.ScannerKit, mlkinetics.InputFunctionKit, mlkinetics.ParcKit, and mlkinetics.ModelKit.
    %
    %  See also the builder pattern (cf. GoF).
    %  
    %  Created 09-Jun-2022 10:25:54 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.

    methods (Abstract)
    end

    methods

        %% make related products, with specialty relationships specified by the factory

        function m = make_bids_med(this, varargin)
            %% from BidsKit
            m = this.bids_kit_.make_bids_med(varargin{:});
        end
        function m = make_handleto_counter(this, varargin)
            %% from TracerKit
            m = this.tracer_kit_.make_handleto_counter(varargin{:});
        end
        function m = make_radionuclides(this, varargin)
            %% from TracerKit
            m = this.tracer_kit_.make_radionuclides(varargin{:});
        end
        function m = make_ref_source(this, varargin)
            %% from TracerKit
            m = this.tracer_kit_.make_ref_source(varargin{:});
        end
        function m = do_make_data(this, varargin)
            %% from ScannerKit
            m = this.scanner_kit_.do_make_data(varargin{:});
        end
        function m = do_make_device(this, varargin)
            %% from ScannerKit
            m = this.scanner_kit_.do_make_device(varargin{:});
        end
        function m = do_make_activity(this, varargin)
            %% from InputFuncKit            
            m = this.input_func_kit_.do_make_activity(varargin{:});
        end
        function m = do_make_activity_density(this, varargin)
            %% from InputFuncKit         
            m = this.input_func_kit_.do_make_activity_density(varargin{:});
        end
        function m = do_make_count_rate(this, varargin)
            %% from InputFuncKit         
            m = this.input_func_kit_.do_make_count_rate(varargin{:});
        end
        function m = make_parc(this, varargin)
            %% from ParcKit
            m = this.parc_kit_.make_parc(varargin{:});
        end
        function m = make_model(this, varargin)
            %% from ModelKit
            m = this.model_kit_.make_model(varargin{:});
        end
        function m = make_solution(this, varargin)
            %% from ModelKit
            m = this.model_kit_.make_solution(varargin{:});
        end
        function save(this)
            saveas(this);
        end
        function saveas(this, fn)
            arguments
                this mlkinetics.KineticsKit
                fn {mustBeTextScalar} = strcat(stackstr(), ".mat")
            end
            save(fn, 'this')
        end

        %% physiological products

        function v1 = do_make_v1(~, varargin)
            %% v1 ~ blood volume \in [0,1]
            v1 = nan;
        end
        function ks = do_make_ks(~, varargin)
            %% ks ~ kinetic rates ~ 1/s
            ks = nan;
        end
        function K1 = do_make_K1(~, varargin)
            %% K1 ~ V1*k1 ~ mL/min/hg
            K1 = nan;
        end
        function E = do_make_E(~, varargin)
            %% E ~ extraction fraction \in [0, 1]
            E = nan;
        end
        function R = do_make_R(this, varargin)
            %% R ~ cerebral metabolic rate ~ \mu mol/min/hg
            ks = this.do_make_ks();
            E = this.do_make_E();
            R = this.do_make_cmr();            
        end
        function Vt = do_make_Vt(~, varargin)
            %% Vt ~ volume of distribution
            Vt = nan;
        end
        function BP = do_make_BP(~, varargin)
            %% BP ~ binding potential
            BP = nan;
        end
        function ga = do_make_ga(~, varargin)
            %% ga ~ graphical analysis results ~ struct
            ga = struct([]);
        end
    end

    methods (Static)
        
        %% convenience create-methods for clients
        
        function this = create(opts)
            arguments                
                opts.bids_tags {mustBeText}   
                opts.bids_fqfn {mustBeText}
                opts.ref_source_props
                opts.tracer_tags {mustBeText}
                opts.counter_tags {mustBeText}
                opts.scanner_tags {mustBeText}
                opts.input_func_tags {mustBeText}
                opts.input_func_fqfn {mustBeText}
                opts.recovery_coeff double = 1
                opts.representation_tags {mustBeText}
                opts.parc_tags {mustBeText}
                opts.data struct = struct([])
                opts.model_tags {mustBeText}
            end
            copts = namedargs2cell(opts);

            if contains(opts.bids_fqfn, ["trc-co","trc-oc","trc-oo","trc-ho"]) || ...
                    contains(opts.tracer_tags, "15o", IgnoreCase=true) || ...
                    contains(opts.input_func_fqfn, ["trc-co","trc-oc","trc-oo","trc-ho"]) || ...
                    any(contains(opts.model_tags, ["cbv","cbf","oef","cmro2","martin","mintun","raichle"], IgnoreCase=true))
                this = mlkinetics.OxyMetabKit.instance(copts{:});
                return
            end
            if contains(opts.bids_fqfn, "trc-fdg") || ...
                    any(contains(opts.model_tags, ["cmrglc","agi","ogi","huang"], IgnoreCase=true))
                this = mlkinetics.GlcMetabKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "1tcm", IgnoreCase=true))
                this = mlkinetics.OneTCMKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "2tcm", IgnoreCase=true))
                this = mlkinetics.TwoTCMKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "patlak", IgnoreCase=true))
                this = mlkinetics.Patlak.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "ichise", IgnoreCase=true)) && ...
                    any(contains(opts.model_tags, "ma", IgnoreCase=true))
                this = mlkinetics.IchiseMAKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "logan", IgnoreCase=true))
                this = mlkinetics.LoganKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "mrtm", IgnoreCase=true))
                this = mlkinetics.MrtmKit.instance(copts{:});
                return
            end
            if any(contains(opts.model_tags, "srtm", IgnoreCase=true))
                this = mlkinetics.SrtmKit.instance(copts{:});
                return
            end

            error("mlkinetics:ValueError", "%s: could not match arguments to a concrete factory method", stackstr())
        end
    end

    %% PROTECTED

    properties (Access = protected)
        bids_kit_       % -> abstract factories implemented as prototypes to reduce # of concrete classes
                        %    supporting Ccir1211Mediator, Ccir993Mediator, Ccir559754Mediator, SimpleMediator, ...
        input_func_kit_ % -> TwiliteKit, CapracKit, HidexKit, FungIdifKit, ReferenceRegionKit, ...
        model_kit_      % -> prototypes ...
        parc_kit_       % -> prototypes ...
        representation_kit_ 
        scanner_kit_    % -> BiographVisionKit2, BiographMMRKit2, EcatExactHRPlusKit2, ...
        tracer_kit_     % -> prototypes ..
    end

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.bids_kit_)
                that.bids_kit_ = copy(this.bids_kit_); end
            if ~isempty(this.input_func_kit_)
                that.input_func_kit_ = copy(this.input_func_kit_); end
            if ~isempty(this.model_kit_)
                that.model_kit_ = copy(this.model_kit_); end
            if ~isempty(this.parc_kit_)
                that.parc_kit_ = copy(this.parc_kit_); end
            if ~isempty(this.scanner_kit_)
                that.scanner_kit_ = copy(this.scanner_kit_); end
            if ~isempty(this.tracer_kit_)
                that.tracer_kit_ = copy(this.tracer_kit_); end
        end
        function install_kinetics(this, opts)
            %% requires named Args
            %  opts.bids_fqfn {mustBeFile}
            %  opts.input_func_tags {mustBeText}

            arguments
                this mlkinetics.KineticsKit
                opts.bids_tags {mustBeText} = ""
                opts.bids_fqfn {mustBeFile}
                opts.ref_source_props = struct([])
                opts.tracer_tags {mustBeText} = ""
                opts.counter_tags {mustBeText} = ""
                opts.scanner_tags {mustBeText} = ""
                opts.input_func_tags {mustBeText} = "mipidif"
                opts.input_func_fqfn {mustBeText} = ""
                opts.representation_tags {mustBeText} = "native"
                opts.parc_tags {mustBeText} = "voxels"
                opts.data struct = struct([])
                opts.model_tags {mustBeText} = ""
                opts.recovery_coeff double = 1
            end

            % BidsKit
            if isemptytext(opts.bids_tags)
                opts.bids_tags = this.find_bids_tags(opts.bids_fqfn);
            end
            this.bids_kit_ = mlkinetics.BidsKit.create( ...
                bids_tags=opts.bids_tags, bids_fqfn=opts.bids_fqfn);

            % TracerKit
            if isempty(opts.ref_source_props)
                med = this.bids_kit_.make_bids_med();
                opts.ref_source_props = datetime(med);
            end
            if isemptytext(opts.tracer_tags)
                opts.tracer_tags = this.find_tracer_tags(opts.bids_fqfn);
            end
            if isemptytext(opts.counter_tags)
                opts.counter_tags = this.find_counter_tags(opts.bids_tags);
            end
            this.tracer_kit_ = mlkinetics.TracerKit.create( ...
                bids_kit=this.bids_kit_, ...
                ref_source_props=opts.ref_source_props, ...
                tracer_tags=opts.tracer_tags, ...
                counter_tags=opts.counter_tags);
            
            % ScannerKit
            if isemptytext(opts.scanner_tags)
                opts.scanner_tags = this.find_scanner_tags(opts.bids_tags);
            end
            this.scanner_kit_ = mlkinetics.ScannerKit.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_, ...
                scanner_tags=opts.scanner_tags);

            % InputFuncKit
            this.input_func_kit_ = mlkinetics.InputFuncKit.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_, ...
                scanner_kit=this.scanner_kit_, ...
                input_func_tags=opts.input_func_tags, ...
                input_func_fqfn=opts.input_func_fqfn, ...
                recovery_coeff=opts.recovery_coeff);        

            % RepresentationKit
            % this.representation_kit_ = mlkinetics.RepresentationKit.create( ...
            %     bids_kit=this.bids_kit_, ...
            %     representation_tags=opts.representation_tags);

            % ParcKit
            this.parc_kit_ = mlkinetics.ParcKit.create( ...
                bids_kit=this.bids_kit_, ...
                parc_tags=opts.parc_tags);

            % ModelKit
            if isemptytext(opts.model_tags)
                opts.model_tags = this.find_model_tags(opts.tracer_tags);
            end
            this.model_kit_ = mlkinetics.ModelKit.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_, ...
                scanner_kit=this.scanner_kit_, ...
                input_func_kit=this.input_func_kit_,...
                parc_kit=this.parc_kit_, ...
                data=opts.data, ...
                model_tags=opts.model_tags);
        end
        function this = KineticsKit()
        end
    end

    %% PRIVATE

    methods (Access = private)
        function tags = find_bids_tags(this, fqfn)
            arguments
                this mlkinetics.KineticsKit
                fqfn {mustBeFile}
            end
            re = regexp(fqfn, fullfile("\S+", "(?<ccir>CCIR(|\-|_)\d+(|_\d*))", "\S+"), "names");
            tags = lower(convertCharsToStrings(re.ccir));
            tags = strrep(strrep(tags, "-", ""), "_", " ");
        end
        function tags = find_counter_tags(this, bids_tags)
            arguments
                this mlkinetics.KineticsKit
                bids_tags {mustBeText}
            end
            if any(contains(bids_tags, ["1211","559","754","970","993"]))
                tags = "caprac";
                return
            end
            if any(contains(bids_tags, ["1349","1351","1384"]))
                tags = ["beckman","hidex"];
                return
            end
        end
        function tags = find_model_tags(this, trc_tags)
            arguments
                this mlkinetics.KineticsKit
                trc_tags {mustBeText}
            end
            if any(contains(trc_tags, ["co","oc"]))
                tags = "martin1987";
                return
            end
            if contains(trc_tags, "oo")
                tags = "mintun1984";
                return
            end
            if contains(trc_tags, "ho")
                tags = "raichle1983";
                return
            end
            if contains(trc_tags, "fdg")
                tags = "huang1980";
                return
            end
        end
        function tags = find_scanner_tags(this, bids_tags)
            arguments
                this mlkinetics.KineticsKit
                bids_tags {mustBeText}
            end
            if any(contains(bids_tags, ["1211","970","1349","1351","1384"]))
                tags = "vision";
                return
            end
            if any(contains(bids_tags, ["559","754","993"]))
                tags = "mmr";
                return
            end
        end
        function tags = find_tracer_tags(this, fqfn)
            arguments
                this mlkinetics.KineticsKit
                fqfn {mustBeFile}
            end
            re = regexp(fqfn, fullfile("\S+", "\S+_trc-(?<trc>\w+)_\S+"), "names");
            tags = convertCharsToStrings(re.trc);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
