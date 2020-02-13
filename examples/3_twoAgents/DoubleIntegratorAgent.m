classdef DoubleIntegratorAgent < handle
    properties
        position
        velocity
        accel
    end
    properties (Access = private)
        tOld
    end
    methods
        function self = DoubleIntegratorAgent()
            % Constructor
            % Default initial conditions
            self.position = [0;0;0];
            self.velocity = [0;0;0];
        end
        
        function update(self,t)
            if isempty(self.tOld)
                self.tOld = t;
            end
            dt = t - self.tOld;
            self.position = self.position + dt*self.velocity;
            self.velocity = self.velocity + dt*self.accel;
            self.tOld = t; % Dont forget this!!
        end
        
        function computeAccel(self, u)
            % A simple "double integrator" agent is just a kinematic model
            % where the controller controls the acceleration.
            self.accel = u;
        end
    end
end
