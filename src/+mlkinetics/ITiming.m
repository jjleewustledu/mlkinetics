classdef (Abstract) ITiming < handle
	%% ITIMING  

	%  $Revision$
 	%  was created 17-Oct-2018 17:02:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
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
    
    methods (Abstract)
        d = datetime(this) % synonym for datetimes
        d = duration(this) % times as seconds
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

