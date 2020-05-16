classdef DynamicsNodeDiscreteMSD < handle
    % DYNAMICSNODEDISCRETEMSD - Mass-spring-damper dynamics, which listens
    % to the the control effort from the controller node. 
    properties 
        frequency
        position
        velocity
        accel
        controlEffort
        
        mass
        springConstant
        dampingConstant
        tOld
    end
        
    
    methods
        function self = DynamicsNodeDiscreteMSD()
            % Constructor - contains default parameters
            self.mass = 4; % kg
            self.springConstant = 0.4; % N/m
            self.dampingConstant = 0.1; % N/(m/s)
            self.position = 5;
            self.velocity = 0;
            self.accel = 0;
            self.controlEffort = 0;
            self.frequency = 200;
        end
        
        function [handles, freq] = createExecutables(self)
            handles(1) = {@self.update};
            freq(1) = self.frequency;
        end
        
        function data = update(self, t)
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
            
            a = self.computeAccel();
            self.position = self.position + dt*self.velocity;
            self.velocity = self.velocity + dt*a;
            self.tOld = t; % Dont forget this!!
            
            data.r = self.position;
            data.v = self.velocity;
            data.a = a;
            
        end
        
        function v_dot = computeAccel(self)
            % Add whatever other functions you want. 
            
            m = self.mass;
            k = self.springConstant;
            c = self.dampingConstant;
            
            r = self.position;
            v = self.velocity;
            u = self.controlEffort;
            v_dot = (1/m)*(u - k*r - c*v);
            
            self.accel = v_dot;
        end
        

    end
    
    methods (Static)
        function transferors = createTransferors()
            % The createTransferors() function is a special function that
            % will be called at the beginning of the simulation. Use this
            % to create listeners to other nodes. 
            
            % Dynamics node listens to control effort.
            % Set up a transferor that takes the u property from the 
            % controller node and updates the controlEffort property of the 
            % dynamics node. These are the 4 properties all transferors 
            % should have:
            uTransferor.eventNode     = 'controller';
            uTransferor.eventArg      = 'u';
            uTransferor.listeningNode = 'dynamics';
            uTransferor.listeningArg  = 'controlEffort'; 
            
            transferors{1} = uTransferor;
        end
    end
end