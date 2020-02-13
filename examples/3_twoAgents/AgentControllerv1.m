classdef AgentControllerv1 < handle
    properties
        k_p
        k_d
        k_c
        r_des
        safetyRadius;
        activationRadius;

        accelMeas
        distMeas
        v_k_1
        tOld
        J_old
        dr_estimate
        maxEffort
        minEffort
    end
    methods
        function self = AgentControllerv1()
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
        
        function u = computeEffort(self,r,v,y_accel,y_dist)
           self.accelMeas = y_accel;
           self.distMeas = y_dist;
           u_col = self.collisionAvoidance(y_accel, y_dist);
           u = self.k_p*(self.r_des - r) + self.k_d*([0;0;0] - v) + self.k_c*u_col;
           u = max(min(u,self.maxEffort),self.minEffort);
        end
        
        function u_col = collisionAvoidance(self, y_accel, y_dist)            
            r_safe = self.safetyRadius;
            r_act = self.activationRadius;
            J = min([0, (y_dist^2 - r_act^2)/(y_dist^2 - r_safe^2)]);
            
            dJdr = (J - self.J_old)./(self.dr_estimate);
            self.J_old = J;
            if isempty(dJdr) 
                dJdr = zeros(3,1);
            end
            % Get rid of nans and infs
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
           if isempty(self.tOld)
               self.tOld = t;
           end
           dt = t - self.tOld;
           y_accel = self.accelMeas;
           
           self.dr_estimate = dt*self.v_k_1 + dt^2*y_accel;
           self.v_k_1 = self.v_k_1 + dt*y_accel;
           self.tOld = t;
        end
        
    end
end