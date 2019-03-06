classdef (Abstract) MetabBuilder < handle & mlpipeline.AbstractHandleBuilder
	%% METABBUILDER  

	%  $Revision$
 	%  was created 17-Dec-2018 00:17:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = MetabBuilder(varargin)
 			%% METABBUILDER
 			%  @param .

 			this = this@mlpipeline.AbstractHandleBuilder(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        aifData_
        tacData_
        calData_
        roiData_
        solver_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

