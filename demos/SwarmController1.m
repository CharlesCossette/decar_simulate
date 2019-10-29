classdef SwarmController1 < handle %
    % Simple controller. MINIMUM WORKING EXAMPLE of a node.
    properties
        numAgents
        numStates
        state        
    end
    
    methods
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% Constructor, Initial Condtions, Update %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Mandatory functions!
        function self = SwarmController1(numAgents)
            % Constructor
            self.numAgents = numAgents;
        end
             
        
        function x0 = initialCondition(self)
            % Initial conditions (if any).
            x0 = [];
            self.numStates = length(x0); 
        end
        
        
        function updateState(self,x)
            % Nothing right now.
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
