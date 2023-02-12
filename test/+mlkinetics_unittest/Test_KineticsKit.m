classdef Test_KineticsKit < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 10:25:54 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlkinetics.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
    end
    
    methods (TestClassSetup)
        function setupKineticsKit(this)
            import mlkinetics.*
            this.testObj_ = KineticsKit();
        end
    end
    
    methods (TestMethodSetup)
        function setupKineticsKitTest(this)
            this.testObj = this.testObj_;
            this.addTeardown(@this.cleanTestMethod)
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
