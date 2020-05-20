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
        
        timestamps % if this property exists in a node, then the timestep 
                   % at which every transferor listeningArg (controlEffort 
                   % in this case) is updated is recorded.
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
        
        function [data, publishers] = update(self, t)
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
            
            % Export data
            data.r = self.position;
            data.v = self.velocity;
            data.a = a;
            
            % Publish data
            publishers(1).topic = 'dyn_position';
            publishers(1).value = self.position;
            publishers(2).topic = 'dyn_velocity';
            publishers(2).value = self.velocity;
            
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
        function subscribers = createSubscribers()
            % Provides a change of subscribers, which each have a topic and
            % where to copy the value - i.e. the destination.
            sub1.topic = 'cont_controlEffort';
            sub1.destination = 'controlEffort';
            
            subscribers{1} = sub1;
        end
    end
end