classdef ControllerNodeDiscreteMSD < handle
    properties (SetObservable,GetObservable)
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
            % Controller node listens to position and velocity
            listeners(1) = addlistener(nodes.dynamics,'position','PostSet',@self.cbPosition);
            listeners(2) = addlistener(nodes.dynamics,'velocity','PostSet',@self.cbVelocity);
        end

        function cbPosition(self, src, evnt)
            self.r = evnt.AffectedObject.position;
        end
        function cbVelocity(self, src, evnt)
            self.v = evnt.AffectedObject.velocity;
        end
        
        function data = update(self,t)
            self.u = self.k_p*(0 - self.r) + self.k_d*(0 - self.v);
            data.u = self.u; %TODO. really annoying to have to do this.
        end
    end
    
    
end