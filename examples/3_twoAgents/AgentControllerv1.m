classdef AgentControllerv1 < handle
    properties
        k_p
        k_d
        k_c
        r_des
        safetyRadius
        activationRadius


        distMeas
        v_k_1
        tOld
        J_old
        r_rel_old
        dr_estimate
        maxEffort
        minEffort
    end
    methods
        function self = AgentControllerv1()
            % Constructor - default properties
            self.k_p = 2;
            self.k_d = 2.5;
            self.k_c = 1;
            self.r_des = [0;0;0];
            self.safetyRadius = 3;
            self.activationRadius = 6;
            
            self.v_k_1 = 0;
            self.maxEffort = 40;
            self.minEffort = -40;
           
        end
        
        function u = computeEffort(self,r,r_rel,y_dist)
           % Computes the control effort on an agent.
           
           % Collision avoidance term using potential function
           u_col = self.collisionAvoidance(r_rel, y_dist);
           
           % Add proportional control
           u = self.k_p*(self.r_des - r) + self.k_c*u_col;
           
           % Controller saturation
           u = max(min(u,self.maxEffort),self.minEffort);
        end
        
        function u_col = collisionAvoidance(self, r_rel, y_dist)
            
            % Compute Potential
            r_safe = self.safetyRadius;
            r_engage = self.activationRadius;
            J = min([0, (y_dist^2 - r_engage^2)/(y_dist^2 - r_safe^2)]);
            
            % Finite difference approximation to the gradient
            if isempty(self.J_old)
                self.J_old = J;
            end
            if isempty(self.r_rel_old)
                self.r_rel_old = r_rel;
            end
            dJdr = (J - self.J_old)./(r_rel - self.r_rel_old);
            self.J_old = J;
            self.r_rel_old = r_rel;
            
            % Analytical Gradient
%             d_rel = y_dist;
%             if d_rel <= r_engage
%                 dJdr = -(4*(r_engage^2 - r_safe^2)*(d_rel^2 - r_engage^2))/(d_rel^2 - r_safe^2)^3*r_rel;
%             else
%                 dJdr = zeros(3,1);
%             end
            
            % Check if empty for whatever reason.
            if isempty(dJdr) || y_dist > r_engage
                dJdr = zeros(3,1);
            end
            % Get rid of nans and infs, caused by no position change.
            for lv1 = 1:length(dJdr)
                if isnan(dJdr(lv1)) || isinf(dJdr(lv1))
                    dJdr(lv1) = 0;
                end
            end
            u_col = -dJdr;
        end
        
        function update(self,t)
           % Need to double integrate the accelerometer to get an estimate
           % for some position change during an interval.
%            if isempty(self.tOld)
%                self.tOld = t;
%            end
%            dt = t - self.tOld;
%            y_accel = self.accelMeas;
%            
%            self.dr_estimate = dt*self.v_k_1 + dt^2*y_accel;
%            self.v_k_1 = self.v_k_1 + dt*y_accel;
%            self.tOld = t;
        end
        
    end
end