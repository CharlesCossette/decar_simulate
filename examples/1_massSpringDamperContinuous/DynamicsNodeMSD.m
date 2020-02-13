classdef DynamicsNodeMSD < handle
    properties
        position
        velocity
        
        mass
        springConstant
        dampingConstant
        initialPosition
        initialVelocity
    end
    
    methods
        function self = DynamicsNodeMSD()
            % Constructor - contains default settings
            self.mass = 4; % kg
            self.springConstant = 0.4; % N/m
            self.dampingConstant = 0.1; % N/(m/s)
            self.initialPosition = 5;
            self.initialVelocity = 0;
        end
        
        function x0 = initialCondition(self)
            % Initial conditions of the state of this node.
            % This function also implicitly defines the number of states in
            % this node.
            %
            % Delete this function if node has no states.
            x0 = [self.initialPosition;
                  self.initialVelocity];
        end
        
        function updateState(self,x)
            % Update relevant node properties from new state x for use.
            % This function is effectively a state "parser" which disects
            % the state stored into variable x into its components. This
            % should correspond with the initialCondition() function
            % 
            % (self, x) are MANDATORY inputs.
            % 
            % Delete this function is node has no states.
            self.position = x(1);
            self.velocity = x(2);
        end
        
        function [v_dot, data] = computeAccel(self, u)
            % Evaluates the dynamics.
            %
            % Add as many methods and calculations as you like, available
            % for calling in MASTER.
            m = self.mass;
            k = self.springConstant;
            c = self.dampingConstant;
            
            r = self.position;
            v = self.velocity;
            
            v_dot = (1/m)*(u - k*r - c*v);
         
            data.springForce = k*r;
            data.dampingForce = c*v;
            data.kineticEnergy = 0.5*m*v^2;
            data.potentialEnergy = 0.5*k*r^2;
        end
    end
end
        
        