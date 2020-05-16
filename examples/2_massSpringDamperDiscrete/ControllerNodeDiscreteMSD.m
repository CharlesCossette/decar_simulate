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
            self.v = 0;
            self.frequency = 100;
        end
        
        function transferors = createTransferors(~)
            vtransferor.eventNode = 'dynamics';
            vtransferor.eventArg = 'velocity';
            vtransferor.listeningNode = 'controller';
            vtransferor.listeningArg = 'v';
            
            rtransferor.eventNode = 'dynamics';
            rtransferor.eventArg = 'position';
            rtransferor.listeningNode = 'controller';
            rtransferor.listeningArg = 'r';
            
            transferors{1} = rtransferor;
            transferors{2} = vtransferor;
        end
        
        function [handles, freq] = createExecutables(self)
            % TODO: remove gainSchedule, create an EKF example instead
            handles(1) = {@self.gainSchedule};
            freq(1) = 0.5;
            handles(2) = {@self.update};
            freq(2) = self.frequency;
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
        
        function gainSchedule(self,t)
            if t > 10
                self.k_p = 8;
                self.k_d = 6;
            end
        end
    end
    
    
end