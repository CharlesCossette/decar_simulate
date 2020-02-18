classdef DynamicsNodeDiscreteMSD < handle
    properties
        position
        velocity
        accel
        
        mass
        springConstant
        dampingConstant
        initialPosition
        initialVelocity
        tOld
    end
        
    
    methods
        function self = DynamicsNodeDiscreteMSD()
            % Constructor - contains default settings
            self.mass = 4; % kg
            self.springConstant = 0.4; % N/m
            self.dampingConstant = 0.1; % N/(m/s)
            self.position = 5;
            self.velocity = 0;
        end
                
        function update(self,t)
            % The update() function is called automatically by the
            % simulator at the user-specified frequency. Do whatever you
            % want with this. The simulator time t is passed for reference.
            %
            % Usually this is used to update some internal state to the
            % next time step, but really this can be used for whatever.
            
            if isempty(self.tOld)
                % This has it automatically initialized to the starting
                % time.
                self.tOld = t;
            end
            dt = t - self.tOld;
            
            self.position = self.position + dt*self.velocity;
            self.velocity = self.velocity + dt*self.accel;
            self.tOld = t; % Dont forget this!!
        end
        
        function v_dot = computeAccel(self,u)
            % Add whatever functions you want, which may or may not be
            % called by master. 
            
            m = self.mass;
            k = self.springConstant;
            c = self.dampingConstant;
            
            r = self.position;
            v = self.velocity;
            
            v_dot = (1/m)*(u - k*r - c*v);
            
            self.accel = v_dot;
        end
    end
end