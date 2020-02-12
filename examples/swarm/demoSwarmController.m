classdef demoSwarmController < handle %
    % Simple controller. MINIMUM WORKING EXAMPLE of a node.
    properties
        numAgents
        numStates
        state        
    end
    
    methods
        function self = demoSwarmController(numAgents)
            % Constructor
            self.numAgents = numAgents;
        end
             
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%                  MAIN                 %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
        function [u, data] = main(self, r)
            % Simple proportional control.
            r_des = [[10;0;0];[-10;0;0];[0;10;0];[0;-10;0]];
            
            e = r_des - r;
            u = 5*e;
            data = [];
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end
