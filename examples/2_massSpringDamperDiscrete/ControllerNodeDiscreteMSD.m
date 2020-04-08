classdef ControllerNodeDiscreteMSD < handle
    % CONTROLLERNODEDISCRETEMSD - Simple example controller node which
    % listens for position and velocity feedback and uses a PD control law.
    % Although this seems like a lot of overhead just to comply with this
    % simulator framework, this is useful for more complicated nodes.
    properties (SetObservable)
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
            self.v = 0;
        end
        
        function listeners = createListeners(self,nodes)
            % The createListeners(nodes) function is a special function
            % that will be called at the beginning of the simulation. Use
            % this to create listeners to other nodes. 
            %
            % Optionally, you can choose to return the listeners as an 
            % argument so that the simulator can construct the
            % interconnection graph.
            
            % Controller node listens to position and velocity
            listeners(1) = addlistener(nodes.dynamics,'position','PostSet',@self.cbPosition);
            listeners(2) = addlistener(nodes.dynamics,'velocity','PostSet',@self.cbVelocity);
        end

        function cbPosition(self, src, evnt)
            % Callback to store position.
            self.r = evnt.AffectedObject.position;
        end
        function cbVelocity(self, src, evnt)
            % Callback to store velocity.
            self.v = evnt.AffectedObject.velocity;
        end
        
        function data = update(self,t)
            % The update method is another special method that will be
            % called at the user-specified node frequency. Use this to
            % update specific values (such as the control effort, in this
            % case), which are most likely listened to by other nodes.
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
            % TODO: make optional.
            
            % PD control with [0;0] setpoint.
            self.u = self.k_p*(0 - self.r) + self.k_d*(0 - self.v);
            data.u = self.u; 
        end
    end
    
    
end