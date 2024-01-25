classdef Test_QuadraticModel < mlkinetics_unittest.Test_Model
    %% line1
    %  line2
    %  
    %  Created 21-Nov-2023 13:47:38 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlkinetics/test/+mlkinetics_unittest.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties
        testObj
    end
    
    methods (Test)
    end
    
    methods (TestMethodSetup)
        function setupQuadraticModelTest(this)
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
