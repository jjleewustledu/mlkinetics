classdef Timing < handle & mlkinetics.ITiming
	%% TIMING  

	%  $Revision$
 	%  was created 17-Oct-2018 17:03:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        PREFERRED_TIMEZONE = 'America/Chicago'
    end
    
	properties (Dependent)
        resetTimeLimits  % time0 := times(1); timeF := times(end)
        times            % all stored times
        time0            % adjustable time window start; >= time(1)                
        timeF            % adjustable time window end; <= times(end)
        timeWindow       % timeF - time0
        timeInterpolants
        indices          % all stored indices
        index0           % index of time0
        indexF           % index of timeF
        indexWindow      % length(indices)
        datetimes        % all stored datetimes
        datetime0        % datetime of time0
        datetimeF        % datetime of timeF
        datetimeWindow   % datetimeF - datetime0
        datetimeInterpolants
        dt               % for timeInterpolants; <= min(diff(times))
    end 

    methods (Static)        
        function tf = isnice(obj) 
            %% ISNICE duration, datetime or numeric
            
            if (isduration(obj)); obj = seconds(obj); end
            if (isdatetime(obj)); obj = seconds(obj - obj(1)); end
            tf = all(isnumeric(obj)) && all(~isempty(obj)) && all(~isnan(obj)) && all(isfinite(obj));
        end
        function tf = isniceDur(obj)
            if (isdatetime(obj))
                tf = false;
                return
            end
            if (isduration(obj)); obj = seconds(obj); end
            tf = all(isnumeric(obj)) && all(~isempty(obj)) && all(~isnan(obj)) && all(isfinite(obj));
        end
        function tf = isniceDat(obj)
            if (isduration(obj))
                tf = false; 
                return
            end
            if (isdatetime(obj)); obj = seconds(obj - obj(1)); end
            tf = all(isnumeric(obj)) && all(~isempty(obj)) && all(~isnan(obj)) && all(isfinite(obj));
        end
        function tf = isniceScalNum(s)
            tf = isscalar(s) && ...
                isnumeric(s) && ~isempty(s) && ~isnan(s) && isfinite(s);
        end
        function s = seconds2num(s)
            %% SECONDS2NUM preserves milliseconds
            
            assert(isduration(s));
            s = milliseconds(s) / 1e3;
        end
    end
    
	methods 
        
        %% GET
        
        %%
		  
 		function this = Timing(varargin)
 			%% TIMING
 			%  @param .

 			this = this@handle(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

