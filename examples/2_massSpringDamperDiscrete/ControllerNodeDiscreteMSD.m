classdef ControllerNodeDiscreteMSD < handle
    properties
        k_p
        k_d
    end
    
    methods
        function self = ControllerNodeDiscreteMSD()
            % Constructor
            self.k_p = -5;
            self.k_d = -5.5;
        end
        
        function u = computeEffort(self,r,v)
            u = self.k_p*r + self.k_d*v;
        end
    end
    
end