classdef Test_Timing < matlab.unittest.TestCase
	%% TEST_TIMING 

	%  Usage:  >> results = run(mlkinetics_unittest.Test_Timing)
 	%          >> result  = run(mlkinetics_unittest.Test_Timing, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 15-Jun-2017 17:34:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlkinetics/test/+mlkinetics_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        datetimeMeas = datetime(2017,1,1,9,0,0,0.0, 'TimeZone', 'America/Chicago')
 		registry
 		testObj
    end
    
	methods (Test)
        function test_ctor_times(this)
 			obj = mlkinetics.Timing( ...
                'times', [0 1 2 4 8], ...
                'datetimeMeasured', this.datetimeMeas);
            this.verifyEqual(obj.times, [0 1 2 4 8]);
            
 			obj = mlkinetics.Timing( ...
                'times', [0.123 1.123 2.123 4.123 8.123], ...
                'datetimeMeasured', this.datetimeMeas);
            this.verifyEqual(obj.times, [0.123 1.123 2.123 4.123 8.123]);
        end
        function test_ctor_datetime(this)
 			obj = mlkinetics.Timing( ...
                'times', this.datetimeMeas + seconds([0 1 2 4 8]), ...
                'datetimeMeasured', this.datetimeMeas);
            this.verifyEqual(obj.times, [0 1 2 4 8]);
            
 			obj = mlkinetics.Timing( ...
                'times', this.datetimeMeas + milliseconds([0.123 1.123 2.123 4.123 8.123] * 1e3), ...
                'datetimeMeasured', this.datetimeMeas);
            this.verifyEqual(obj.times, [0.123 1.123 2.123 4.123 8.123]);
        end
        function test_times(this)
            % get
            this.verifyEqual(this.testObj.times, 100:199);
            % set
            this.testObj.times = 0:99;
            this.verifyEqual(this.testObj.times, 0:99);
            % set scalar
            this.testObj.times = 0;
            this.verifyEqual(this.testObj.times, 0);
            % set negative
            this.testObj.times = 0:-1:-99;
            this.verifyEqual(this.testObj.times, 0:-1:-99);
        end
        function test_time0(this)
            % get
            this.verifyEqual(this.testObj.time0, 100);
            
            % set out of boundaries
            this.assertWarning(@time0TooEarly, 'mlkinetics:ValueWarning');
            this.assertError(  @time0TooLate, 'mlkinetics:ValueError');            
            % set boundaries            
            this.testObj.time0 = 199;
            this.verifyEqual(this.testObj.index0, 100);
            this.verifyEqual(this.testObj.time0, 199);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas + seconds(99));
            this.verifyEqual(this.testObj.timeWindow, 0);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(0)); 
            
            % set incr
            this.testObj.time0 = 101;
            this.verifyEqual(this.testObj.index0, 2);
            this.verifyEqual(this.testObj.time0, 101);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas + seconds(1));
            this.verifyEqual(this.testObj.timeWindow, 98);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,98)); 
            % set deeper
            this.testObj.time0 = 198;
            this.verifyEqual(this.testObj.index0, 99);
            this.verifyEqual(this.testObj.time0, 198);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas + seconds(98));
            this.verifyEqual(this.testObj.timeWindow, 1);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(1)); 
            % reset
            this.testObj.time0 = 100;
            this.verifyEqual(this.testObj.index0, 1);
            this.verifyEqual(this.testObj.time0, 100);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas);
            this.verifyEqual(this.testObj.timeWindow, 99);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(99)); 
            
            function time0TooEarly()
                this.testObj.time0 = this.testObj.times(1) - 1;
            end
            function time0TooLate()
                this.testObj.time0 = this.testObj.times(end) + 1;
            end
        end
        function test_timeF(this)
            % get
            this.verifyEqual(this.testObj.timeF, 199);
            
            % set out of boundaries
            this.assertError(  @timeFTooEarly, 'mlkinetics:ValueError');
            this.assertWarning(@timeFTooLate, 'mlkinetics:ValueWarning');    
            this.verifyEqual(this.testObj.timeF, 199);
            % set boundaries
            this.testObj.timeF = 100;
            this.verifyEqual(this.testObj.indexF, 1);
            this.verifyEqual(this.testObj.timeF, 100);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas);
            this.verifyEqual(this.testObj.timeWindow, 0);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(0));
            
            % set decr
            this.testObj.timeF = 198;
            this.verifyEqual(this.testObj.indexF, 99);
            this.verifyEqual(this.testObj.timeF, 198);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(98));
            this.verifyEqual(this.testObj.timeWindow, 98);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(98)); 
            % set deeper
            this.testObj.timeF = 101;
            this.verifyEqual(this.testObj.indexF, 2);
            this.verifyEqual(this.testObj.timeF, 101);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(1));
            this.verifyEqual(this.testObj.timeWindow, 1);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(1)); 
            % reset
            this.testObj.timeF = 199;
            this.verifyEqual(this.testObj.indexF, 100);
            this.verifyEqual(this.testObj.timeF, 199);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(99));
            this.verifyEqual(this.testObj.timeWindow, 99);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(99)); 
            
            function timeFTooEarly()
                this.testObj.timeF = this.testObj.times(1) - 1;
            end
            function timeFTooLate()
                this.testObj.timeF = this.testObj.times(end) + 1;
            end
        end
		function test_timeWindow(this)
            % get
            this.verifyEqual(this.testObj.timeWindow, 99);         
            % set
            this.testObj.timeWindow = 50;
            this.verifyEqual(this.testObj.indexF, 51);
            this.verifyEqual(this.testObj.timeF, 150);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(50));
            this.verifyEqual(this.testObj.timeWindow, 50);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(50));
            % set min
            this.testObj.timeWindow = 0;
            this.verifyEqual(this.testObj.indexF, 1);
            this.verifyEqual(this.testObj.timeF, 100);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas);
            this.verifyEqual(this.testObj.timeWindow, 0);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(0));
            % set sup
            this.verifyWarning(@timeWindowTooLong, 'mlkinetics:ValueWarning');
            this.verifyEqual(this.testObj.indexF, 100);
            this.verifyEqual(this.testObj.timeF, 199);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(99));
            this.verifyEqual(this.testObj.timeWindow, 99);
            this.verifyEqual(this.testObj.datetimeWindow, seconds(99));
            
            function timeWindowTooLong()
                this.testObj.timeWindow = 100;
            end
        end
        function test_timeInterpolants(this)
            this.verifyEqual(this.testObj.timeInterpolants, 100:0.5:199);
            this.testObj.dt = 0.25;
            this.verifyEqual(this.testObj.timeInterpolants, 100:0.25:199);
        end
        function test_indices(this)
            this.verifyEqual(this.testObj.indices, 1:100);
        end
        function test_index0(this)
            % get            
            this.verifyEqual(this.testObj.index0, 1);
            % set
            this.testObj.index0 = 51;
            this.verifyEqual(this.testObj.index0, 51);
            this.verifyEqual(this.testObj.time0, 150);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas + seconds(50));
            this.verifyEqual(this.testObj.timeWindow, 49);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,49)); 
        end
        function test_indexF(this)
            % get
            this.verifyEqual(this.testObj.indexF, 100);
            % set
            this.testObj.indexF = 51;
            this.verifyEqual(this.testObj.indexF, 51);
            this.verifyEqual(this.testObj.timeF, 150);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(50));
            this.verifyEqual(this.testObj.timeWindow, 50);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,50)); 
        end
        function test_datetimes(this)
            ve(this.testObj);
            this.testObj.time0 = 133;
            ve(this.testObj);
            this.testObj.timeF = 166;
            ve(this.testObj);
            this.testObj.index0 = 33;
            ve(this.testObj);
            this.testObj.indexF = 66;
            ve(this.testObj);
            
            function ve(obj)
                d = obj.datetime;
                this.verifyEqual(d(1),   this.datetimeMeas);
                this.verifyEqual(d(end), this.datetimeMeas + seconds(99));
            end
        end
        function test_datetime0(this)
            % get
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas);
            % set
            this.testObj.datetime0 = this.datetimeMeas + seconds(1);
            this.verifyEqual(this.testObj.index0, 2);
            this.verifyEqual(this.testObj.time0, 101);
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas + seconds(1));
            this.verifyEqual(this.testObj.timeWindow, 98);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,98));
        end
        function test_datetimeF(this)
            % get
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(99));
            % set
            this.testObj.datetimeF = this.datetimeMeas + seconds(98);
            this.verifyEqual(this.testObj.indexF, 99);
            this.verifyEqual(this.testObj.timeF, 198);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(98));
            this.verifyEqual(this.testObj.timeWindow, 98);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,98));
        end
		function test_datetimeWindow(this)
            % get
            this.verifyEqual(this.testObj.datetimeWindow, seconds(99));         
            % set
            this.testObj.datetimeWindow = seconds(50);
            this.verifyEqual(this.testObj.indexF, 51);
            this.verifyEqual(this.testObj.timeF, 150);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(50));
            this.verifyEqual(this.testObj.timeWindow, 50);
            this.verifyEqual(this.testObj.datetimeWindow, duration(0,0,50)); 
        end
        function test_datetimeMeasured(this)
            this.verifyEqual(this.testObj.datetimeMeasured, this.datetimeMeas);
        end
        function test_dt(this)
            % get            
            this.verifyEqual(this.testObj.dt, 0.5);
            % set
            this.testObj.dt = 1;
            this.verifyEqual(this.testObj.dt, 1);
            this.verifyEqual(this.testObj.timeInterpolants, 100:199);
        end        
        
        function test_datetime(this)
            this.verifyEqual(datetime(this.testObj), this.testObj.datetimes);
            this.verifyEqual(datetime(this.testObj), this.datetimeMeas + seconds(0:99));
        end
        function test_duration(this)
            this.verifyEqual(duration(this.testObj), seconds(100:199));
        end
        function test_num2datetime(this)
            dt = datetime(2017,1,1,9,0,1,123, 'TimeZone', 'America/Chicago');        
            this.assertEqual(this.testObj.num2datetime(1.123), dt); 
        end
        function test_num2duration(this)
            this.assertEqual(this.testObj.num2duration(1.123), milliseconds(1123));
        end
        function test_resetTimeLimits(this)
            this.testObj.time0 = 133;
            this.testObj.timeF = 166;
            this.testObj.resetTimeLimits;
            this.verifyEqual(this.testObj.time0, 100);
            this.verifyEqual(this.testObj.timeF, 199);
            
            this.testObj.index0 = 33;
            this.testObj.indexF = 66;
            this.testObj.resetTimeLimits;
            this.verifyEqual(this.testObj.index0, 1);
            this.verifyEqual(this.testObj.indexF, 100);
            
            this.testObj.datetime0 = this.datetimeMeas + seconds(33);
            this.testObj.datetimeF = this.datetimeMeas + seconds(66);
            this.testObj.resetTimeLimits;
            this.verifyEqual(this.testObj.datetime0, this.datetimeMeas);
            this.verifyEqual(this.testObj.datetimeF, this.datetimeMeas + seconds(99));
        end
        function test_timing2num(this)
            % retains subseconds
            
            this.assertEqual(this.testObj.timing2num(milliseconds(1123)), 1.123);
            this.assertEqual(this.testObj.timing2num(seconds(1.123)), 1.123);
            this.assertEqual(this.testObj.timing2num(minutes(1.123/60)), 1.123);
            this.assertEqual(this.testObj.timing2num(hours(1.123/3600)), 1.123);
            
            dt = datetime(2017,1,1,9,0,1,123, 'TimeZone', 'America/Chicago');        
            this.assertEqual(this.testObj.timing2num(dt), 1.123);            
        end
    end

 	methods (TestClassSetup)
		function setupTiming(this)
 		end
	end

 	methods (TestMethodSetup)
		function setupTimingTest(this)
 			this.testObj = mlkinetics.Timing( ...
                'datetimeMeasured', this.datetimeMeas, ...
                'times', 100:199);
 			this.addTeardown(@this.cleanFiles);
 		end
	end
    
    %% PRIVATE

	properties (Access = private)
 	end

	methods (Access = private)
        function assignLargeTimeDuration(this)
            this.testObj.timeWindow = 100;
        end
		function cleanFiles(this)
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

