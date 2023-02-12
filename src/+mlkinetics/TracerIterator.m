classdef TracerIterator < handle & mlpatterns.Iterator
    %% TracerIterator is an iterator design pattern
    %  
    %  Created 13-Jun-2022 21:29:56 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods
        function this = TracerIterator(varargin)
            %% TRACERITERATOR 
            %  Args:
            %      patt (text): pattern for glob().
            %  Returns:
            %      this.collection:  protected collection of mlfourd.ImagingContext2->FilesytemTool.
                        
            ip = inputParser;
            addRequired(ip, "kinetics_kit", @(x) isa(x, "mlkinetics.KineticsKit"))
            addParameter(ip, "patt", "*_trc-*_*.nii.gz", @istext);
            addParameter(ip, "taus", [], @(x) isa(x, 'function_handle') || isa(x, 'containers.Map'));
            parse(ip, varargin{:})
            ipr = ip.Results;

            this.collection = {};
            for g = glob(ipr.patt)
                imaging = mlfourd.ImagingContext2(g{1});
                re = regexp(g{1}, '\S+_trc-(?<trc>\w+)_\S+', 'names');
                this.collection = [this.collection, ipr.kinetics_kit.make_tracer(imaging, ipr.taus(re.trc))];
            end
            this.index = 0;
        end

        function elts = currentItem(this)
            try
                elts = this.collection{this.index};
            catch ME
                if strcmp(ME.identifier, 'MATLAB:badsubscript')
                    error('mlkinetics:ValueError', ...
                        'TracerIterator.currentItem is not available for index->%i', this.index);
                end
                rethrow(ME);
            end
        end
        function tf = hasNext(this)
            tf = this.index + 1 <= length(this.collection);
        end
        function elts = next(this)
            this.index = this.index + 1;
            elts = this.collection{this.index};
        end
        function reset(this)
            this.index = 0;
        end        
    end

    %% PROTECTED

    properties (Access = protected)
        index
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
