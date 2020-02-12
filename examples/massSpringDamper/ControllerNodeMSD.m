classdef ControllerNodeMSD < handle
    % Simple PD controller.
    % Example of a node with no states.
    properties
        k_p
        k_d
    end
    
    methods
        function self = ControllerNodeMSD()
            self.k_p = -4;
            self.k_d = -5.5;
        end
        
        function [u, data] = computeEffort(self,r,v)
            u = self.k_p*r + self.k_d*v;
            
            data.p_term = self.k_p*r;
            data.d_term = self.k_d*v;
        end
    end
end