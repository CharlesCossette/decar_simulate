classdef AgentControllerv1 < handle
    properties
        k_p
        k_d
        k_c
        r_des
    end
    methods
        function self = AgentControllerv1()
            self.k_p = 2;
            self.k_d = 2.5;
            self.k_c = 1;
            self.r_des = [0;0;0];
        end
        
        function u = computeEffort(self,r,v,y_accel,y_dist)
           u_col = self.collisionAvoidance(y_accel, y_dist);
           u = self.k_p*(self.r_des - r) + self.k_d*([0;0;0] - v) + u_col;
        end
        
        function u_col = collisionAvoidance(self, y_accel, y_dist)
            u_col = [0;0;0];
        end
        
    end
end