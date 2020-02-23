classdef SingleIntegratorAgent < handle
    properties
        position
        velocity
        outPosition
        outVelocity
        inControlEffort
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
            self.inControlEffort = [0;0;0];
            self.outPosition = self.position;
            self.outVelocity = self.velocity;
        end
        
        function update(self,t)
            % Calculate dt
            if isempty(self.tOld)
                self.tOld = t;
            end
            dt = t - self.tOld;
            self.tOld = t; % Dont forget this!!
            
            % Compute dynamics
            self.velocity = self.computeVelocity();
            
            % Update to next step
            self.position = self.position + dt*self.velocity;
     
            % Publish properties for other nodes.
            self.outPosition = self.position;
            self.outVelocity = self.velocity;
        end
        
        function v = computeVelocity(self)
            % Single integrator agent has the control effort directly
            % control the velocity.
            v = self.inControlEffort;
        end
        
       
    end
end
