classdef ControllerNodeDiscreteMSD < handle
    % CONTROLLERNODEDISCRETEMSD - Simple example controller node which
    % listens for position and velocity feedback and uses a PD control law.
    % Although this seems like a lot of overhead just to comply with this
    % simulator framework, this is useful for more complicated nodes.
    
    properties
        frequency
        k_p
        k_d
        u
        r
        v
    end
    
    methods
        function self = ControllerNodeDiscreteMSD()
            % Constructor
            self.k_p = 5;
            self.k_d = 5.5;
            self.u = 0;
            self.r = 0;
            self.v.value = 0;
            self.v.t = 0;
            self.frequency = 100;
        end
        
        
        function [handles, freq] = createExecutables(self)
            % TODO: remove gainSchedule, create an EKF example instead
            handles(1) = {@self.gainSchedule};
            freq(1) = 0.5;
            handles(2) = {@self.update};
            freq(2) = self.frequency;
        end
        
        function subscribers = createSubscribers(~)
            % Subscribe to the 'dyn_position' topic
            sub1.topic = 'dyn_position';
            sub1.destination = 'r';
            %sub1.callback = @self.someCallback % Could even have callbacks
            
            % Subscribe to the 'dyn_velocity' topic WITH TIMESTAMPS.
            sub2.topic = 'dyn_velocity';
            sub2.destination = 'v';
            sub2.timestamps = true;
            
            % We could actually use a struct array instead of cells. I.e.
            % do subscribers(1).topic = 'dyn_position';
            subscribers{1} = sub1;
            subscribers{2} = sub2;            
        end
        
        function [data, publishers] = update(self,t)
            % This method is an example of an executable. Here we use this 
            % uto pdate specific values (such as the control effort, in this
            % case), which are most likely subscribed to by other nodes.
            %
            % Inputs
            % -------
            % t - actual simulation time in seconds. Use this to construct
            % a "dt" if neeeded.
            %
            % Outputs
            % -------
            % data - mandatory struct saving any interesting data at that
            % time step. The simulator will agregate this from all the time
            % steps for plotting later. If no data, return an empty struct:
            % data = struct()
            
            % Here, since we chose to have timestamps for the velocity, we
            % must specifically access the "value" field. Otherwise the
            % value can be put directly into self.v
            vel = self.v.value;
            vel_timestamp = self.v.t; % How to access the timestamp.
            
            % PD control with [0;0] setpoint.
            self.u = self.k_p*(0 - self.r) + self.k_d*(0 - vel);
            data.u = self.u; 
            
            % Publish for other nodes
            % TODO: Need to choose between cell array or struct array
            publishers(1).topic = 'cont_controlEffort';
            publishers(1).value = self.u;
        end
        
        function gainSchedule(self,t)
            if t > 10
                self.k_p = 8;
                self.k_d = 6;
            end
        end
    end
    
    
end