classdef OxyMetabBids < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 03-Aug-2023 11:37:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.14.0.2306882 (R2023a) Update 4 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function obj = aifsOnAtlas(this, varargin)
            tr = lower(this.bids_med_.tracer);
            obj = this.metricOnAtlas(['aif_' tr], varargin{:});
        end
        function obj = cbfOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbf', varargin{:});
        end
        function obj = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj = cmrgclOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmrglc', varargin{:});            
        end
        function obj = cmro2OnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmro2', varargin{:});            
        end
        function obj = dlicv(this, varargin)
            obj = this.bids.dlicv_ic(varargin{:});
        end
        function obj = fsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fs', varargin{:});
        end
        function obj = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function obj = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonly is logical.
            %  @param tags is char, e.g., 'b43_wmparc1', default ''.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.bids_med_.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;

            try
                g = glob(fullfile(this.bids_med_.scanPath, ...
                    sprintf('*_%s_*%s*.nii.gz', metric, ipr.tags)));
                if ~isempty(g)
                    obj = mlfourd.ImagingContext2(g{1});
                    return
                end
            catch ME
                handexcept(ME)
            end
            
            if ~isempty(ipr.tags)
                ipr.tags = strip(ipr.tags, "_");
            end   
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['ses-' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['ses-' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            
            s = this.bids.filename2struct(this.bids_med_.imagingContext.fqfn);
            s.ses = adatestr;
            s.modal = ipr.metric;
            s.tag = ipr.tags;
            fqfn = this.bids.struct2filename(s);
            obj = mlfourd.ImagingContext2(fqfn);
        end	
        function obj = osOnAtlas(this, varargin)
            obj = this.metricOnAtlas('os', varargin{:});
        end
        function obj = roiOnAtlas(this, idx, varargin)
            obj = this.metricOnAtlas(sprintf('index%g', idx), varargin{:});
        end
        function obj = venousOnAtlas(this, varargin)
            obj = this.metricOnAtlas('venous', varargin{:});
        end
        function obj = vsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('vs', varargin{:});
        end
        function obj = wmparc1OnAtlas(this, varargin)
            %% idx == 40:  venuos voxels
            %  idx == 1:   extraparenchymal CSF, not ventricles

            import mlfourd.ImagingFormatContext2
            import mlfourd.ImagingContext2

            if ~isempty(this.wmparc1OnAtlas_)
                obj = this.wmparc1OnAtlas_;
                return
            end

            obj = this.metricOnAtlas('wmparc1', varargin{:});
            fqfn = obj.fqfn;
            if isfile(fqfn)
                this.wmparc1OnAtlas_ = obj;
                return
            end
            
            pwd0 = pushd(myfileparts(fqfn));
            
            % constructWmparcOnAtlas
            bids_ = this.bids;
            out_ = fullfile(bids_.t1w_ic.filepath, 'T1_on_T1w.nii.gz');
            omat_ = strrep(out_, '.nii.gz', '.mat');
            flirting = mlfsl.Flirt( ...
                'in', bids_.T1_ic.fqfn, ...
                'ref', bids_.t1w_ic.fqfn, ...
                'out', out_, ...
                'omat', omat_, ...
                'bins', 256, ...
                'cost', 'corratio', ...
                'dof', 6, ...
                'interp', 'nearestneighbour');
            flirting.flirt();
            flirting.in = bids_.wmparc_ic.fqfn;
            flirting.out = this.metricOnAtlas('wmparc', varargin{:}).fqfn;
            flirting.applyXfm();
            
            % define CSF; idx := 1
            wmparc = flirting.out.imagingFormat;
            %wmparc.selectNiftiTool();
            wmparc1 = this.dlicv.imagingFormat; % establish ICV := CSF + parenchyma
            %wmparc1.selectNiftiTool();
            
            % define venous; idx := 40
            ven = this.cbvOnAtlas();
            ven = ven.blurred(this.bids_med_.petPointSpread);
            ven = ven.thresh(dipmax(ven)/2);
            ven = ven.binarized();
            ven.fqfn = this.venousOnAtlas().fqfn;
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            selected = logical(ven.imagingFormat.img) & 1 == wmparc1.img;
            wmparc1.img(selected) = 40; % co-opting right cerebral exterior            

            % assign wmparc indices
            wmparc1.img = int32(wmparc1.img);
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);

            % construct wmparc1
            obj = ImagingContext2(wmparc1);
            obj.fqfn = fqfn;
            obj.save();
            this.wmparc1OnAtlas_ = obj;

            popd(pwd0);
        end
    end

    methods (Static)
        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
            end

            this = mlkinetics.OxyMetabBids();
            this.bids_kit_ = opts.bids_kit;
            this.bids_med_ = this.bids_kit_.make_bids_med();
        end
    end

    %% PRIVATE

    properties (Access = private)
        bids_kit_
        bids_med_
    end

    methods (Access = private)
        function this = OxyMetabBids()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
