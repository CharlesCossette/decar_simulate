classdef SingleIntegratorAgent < handle
    properties
        position
        velocity
    end
    properties (Access = private)
        tOld
    end
    methods
        function self = SingleIntegratorAgent()
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
            self.tOld = t; % Dont forget this!!
        end
        
        function computeVelocity(self, u)
            % A simple "single integrator" agent is just a kinematic model
            % where the controller controls the velocity.
            self.velocity = u;
        end
    end
end
