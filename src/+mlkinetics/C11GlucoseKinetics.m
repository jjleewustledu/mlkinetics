classdef C11GlucoseKinetics 
	%% C11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 21-Jan-2016 16:56:18
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/src/+mlkinetics.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2016 John Joowon Lee.
 	

	properties
 		
 	end

	methods 
		  
 		function this = C11GlucoseKinetics(varargin)
 			%% C11GLUCOSEKINETICS
 			%  Usage:  this = C11GlucoseKinetics()

 			
        end
    end
    
    methods (Static)
        function [output,t2] = loopRegionsLocally
            studyDat = mlpipeline.StudyDataSingleton.instance('arbelaez:GluT');            
            t0 = tic;
            studyDat.diaryOn;
            sessPths = studyDat.sessionPaths;
            regions = studyDat.regionNames;            
            output = cell(length(sessPths), length(studyDat.numberOfScans), length(regions));
            
            for p = 1:length(sessPths)
                for s = 1:length(studyDat.numberOfScans)
                    for r = 1:length(regions)
                        try
                            t1 = tic;
                            fprintf('%s:  is working with %s scanIndex %i region %s\n', mfilename, sessPths{d}, s, regions{r});
                            rm = RegionalMeasurements(fullfile(sDir, sessPths{d}, ''), s, regions{r});
                            [v,rm] = rm.vFrac;
                            [f,rm] = rm.fFrac;
                            k = rm.kinetics4; 
                            k = k.parameters;
                            output{d,s,r} = struct('v', v, 'f', f, 'k4parameters', k);
                            fprintf('Elapsed time:  %g seconds\n\n\n\n', toc(t1));
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
            
            studyDat.saveWorkspace;
            t2 = toc(t0);
            studyDat.diaryOff;
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

