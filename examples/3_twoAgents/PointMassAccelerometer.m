classdef PointMassAccelerometer < handle
    properties
        bias
        stdDev
    end
    methods
        function self = PointMassAccelerometer()
            self.bias = [0;0;0];
            self.stdDev = 0.2*ones(3,1);
        end
        function y = measurement(self,trueAccel)
            % Add noise to true to create measurement. 
            if isempty(trueAccel)
                trueAccel = [0;0;0];
            end
            y = trueAccel + randn(3,1).*self.stdDev + self.bias;
        end
    end
end