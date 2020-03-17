classdef AgentControllerExample < handle
    properties (SetObservable)
        controlEffort
    end
    properties
        ID
        k_p
        k_c
        r_zrw_a
        engagementRadius
        safetyRadius
        maxEffort
        
        % Listener variables
        r_zw_a
        r_21_a
    end
    properties (Access = private)
        % Working variables
        dt
        tOld
    end
    
    methods
        function self = AgentControllerExample(agentID)
            % Constructor
            self.ID = agentID;
            self.k_p = 2;
            self.k_c = 1;
            self.engagementRadius = 8;
            self.safetyRadius = 3;
            self.maxEffort = 40;
            self.r_21_a = [0;0;0];
            self.r_zw_a = [0;0;0];
           
        end
        
        function L = createListeners(self,nodes)
            L(1) = addlistener(nodes.(['agent',num2str(self.ID)]), 'position', 'PostSet', @self.cbPosition);
            L(2) = addlistener(nodes.(['relPosSensor',num2str(self.ID)]), 'measurement', 'PostSet', @self.cbUwb);
        end
        
        function cbPosition(self,~,evnt)
            self.r_zw_a = evnt.AffectedObject.position;
        end
        
        function cbUwb(self,~,evnt)
            y = evnt.AffectedObject.measurement;
            if isempty(y)
                y = zeros(3,1);
            end
            self.r_21_a = y;
        end
        
        function data = update(self,t)
            % Calculate dt
            if isempty(self.tOld)
                self.tOld = t; % Doing this means we detect the start time.
            end
            self.dt = t - self.tOld;
            self.tOld = t;
            
            self.controlEffort = self.updateEffort(self.dt, self.r_zw_a, ...
                self.r_zrw_a, self.r_21_a);
            data.u = self.controlEffort;
        end
        
        function u_tot = updateEffort(self,dt, r_1w_a, r_1rw_a, r_21_a)
            % Position error (setpoint - current position)
            e = r_1rw_a - r_1w_a;
            
            % Collision avoidance control effort
            u_col = self.collisionAvoidance(dt, r_21_a);
            
            % Task-level control effort (go to waypoint)
            u_task = self.k_p*e;
            
            % Total control effort
            u_tot = u_task + u_col;
            
            % Saturate
            u_tot = max(min(u_tot, self.maxEffort), -self.maxEffort);
        end
        
    end
    methods (Access = private)
        function u_col = collisionAvoidance(self,dt, r_21_a)
            % Potential function-based control law
            
            % Safety and activation radius
            r_engage = self.engagementRadius;
            r_safe = self.safetyRadius;
            d_21 = norm(r_21_a);
            
            % Analytical gradient
            if d_21 <= r_engage && d_21 > r_safe
                dJdr = -(4*(r_engage^2 - r_safe^2)*(d_21^2 - r_engage^2))/(d_21^2 - r_safe^2)^3*r_21_a;
            else
                dJdr = zeros(3,1);
            end
            
            u_col = -dJdr;
        end
    end
end
