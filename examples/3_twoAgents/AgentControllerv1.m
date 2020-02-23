classdef AgentControllerv1 < handle
    properties
        k_p
        k_c
        r_zrw_a
        method
        outControlEffort
        engagementRadius
        safetyRadius
        lowPassFreq
        maxEffort
        
        % Input variables (must be updated in master)
        r_zw_a
        r_21_a
        y_UWB
    end
    properties (Access = private)
        % Working variables
        dt
        u
        yLowPassOld = [0;0;0];
        JOld = 0
        tOld
        r_21_a_old = [0;0;0];
    end
    methods
        function self = AgentControllerv1()
            % Constructor
            self.k_p = 2;
            self.k_c = 1;
            self.method = 'FD';
            self.engagementRadius = 8;
            self.safetyRadius = 3;
            self.lowPassFreq = 10;
            self.maxEffort = 40;
            self.outControlEffort = [0;0;0];
        end
        
        function update(self,t)
            % Calculate dt
            if isempty(self.tOld)
                self.tOld = t; % Doing this means we detect the start time.
            end
            self.dt = t - self.tOld;
            self.tOld = t;
            
            self.outControlEffort = self.updateEffort(self.dt, self.r_zw_a, ...
                                                 self.r_zrw_a, self.r_21_a,...
                                                 self.y_UWB);
        end
        
        function u_tot = updateEffort(self,dt, r_1w_a, r_1rw_a, r_21_a, y_UWB)
            
            % Position error (setpoint - current position)
            e = r_1rw_a - r_1w_a; 
            
            % Collision avoidance control effort
            u_col = self.collisionAvoidance(dt, r_21_a, y_UWB);
            
            % Task-level control effort (go to waypoint
            u_task = self.k_p*e;
            
            % Total control effort
            u_tot = u_task + u_col;
            
            % Saturate
            u_tot = max(min(u_tot, self.maxEffort), -self.maxEffort);
            
            self.u = u_tot;
            
        end    
       
    end
    methods (Access = private)
        function u_col = collisionAvoidance(self,dt, r_21_a, d_21)
            % Potential function-based control law
            
            % Safety and activation radius
            r_engage = self.engagementRadius;
            r_safe = self.safetyRadius;
            
            % Two different strategies
            if strcmp(self.method,'FD')
                % Finite-difference collision avoidance scheme.
                % Cost function
                J = min([0,(d_21^2 - r_engage^2)/(d_21^2 - r_safe^2)])^2;
                
                % Finite difference gradient approximation
                dJdr = -(J - self.JOld)./(r_21_a - self.r_21_a_old);
                
                % Get rid of nans and infs, caused by no position change.
                for lv2 = 1:length(dJdr)
                    if isnan(dJdr(lv2)) || isinf(dJdr(lv2))
                        dJdr(lv2) = 0;
                    end
                end
                
                % Low-pass filter
                dJdr = (1 - self.lowPassFreq*dt)*self.yLowPassOld ...
                       + self.lowPassFreq*dt*dJdr;
                
                % Set old variables
                self.JOld = J;
                self.yLowPassOld = dJdr;
                self.r_21_a_old = r_21_a;
                
            elseif strcmp(self.method,'analytical')
                % Analytical gradient
                if d_21 <= r_engage
                     dJdr = -(4*(r_engage^2 - r_safe^2)*(d_21^2 - r_engage^2))/(d_21^2 - r_safe^2)^3*r_21_a;
                else
                     dJdr = zeros(3,1);
                end
            end
            
            u_col = -dJdr;
        end
    end
end