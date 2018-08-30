classdef (Abstract) AbstractKineticsDirector < handle & mlkinetics.IHandleKineticsDirector
	%% ABSTRACTKINETICSDIRECTOR provides methods:  diagnose, plot, writetable.

	%  $Revision$
 	%  was created 12-Dec-2017 19:27:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    
    
    %% PROTECTED
    
    properties (Access = protected)        
        kineticsBuilder_
        roisBuilder_
    end
    
    methods (Access = protected)
        function this = AbstractKineticsDirector(varargin)
            %% ABSTRACTKINETICSDIRECTOR
 			%  @param kineticsBldr is an mlkinetics.IHandleKineticsBuilder.
            %  @param roisBldr     is an mlrois.IRoisBuilder.
            
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'kineticsBldr', [],               @(x) isa(x, 'mlkinetics.IHandleKineticsBuilder'));
            addParameter(ip, 'roisBldr', this.defaultRoisBldr, @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            this.kineticsBuilder_ = ip.Results.kineticsBldr;
            this.roisBuilder_     = ip.Results.roisBldr;
        end
        function bldr = defaultRoisBldr(~)
            bldr = mlrois.UnitBuilder;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

