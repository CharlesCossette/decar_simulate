classdef SingleIntegratorAgent < handle
    properties (SetObservable)
        ID
        position
        velocity
    end
    properties (Access = private)
        tOld
        controlEffort
    end
    methods
        function self = SingleIntegratorAgent(agentID)
            % Constructor
            % Default initial conditions
            self.ID = agentID;
            self.position = [0;0;0];
            self.velocity = [0;0;0];
            self.controlEffort = [0;0;0];
        end
        
        function createListeners(self,nodes)
            addlistener(nodes.(['agent',num2str(self.ID),'controller']),...
                'controlEffort','PostSet',@self.cbControlEffort)
        end
        
        function cbControlEffort(self,src,evnt)
            u = evnt.AffectedObject.controlEffort;
            if isempty(u)
                u = zeros(3,1);
            end
            self.controlEffort = u;
        end
        
        function data = update(self,t)
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
            
            data.r = self.position;
            data.v = self.velocity;
        end
        
        function v = computeVelocity(self)
            % Single integrator agent has the control effort directly
            % control the velocity.
            v = self.controlEffort;
        end
        
        
    end
end
