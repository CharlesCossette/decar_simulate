classdef demoSwarmDynamics < handle 
    % Only single-integrator dynamics right now.
    properties
        numAgents
        state
        position
        velocity
        initialPosition
        initialVelocity        
    end
    
    methods
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%% Constructor, Initial Condtions, Update %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Mandatory functions!
        function self = demoSwarmDynamics(numAgents)
            % Constructor
            self.numAgents = numAgents;
            r0 = normrnd(0,10,[3, self.numAgents]);
            v0 = zeros(size(r0));
            self.initialPosition = r0(:);
            self.initialVelocity = v0(:);
        end
             
        function x0 = initialCondition(self)
            % Initial conditions
            x0 = self.initialPosition(:);   
        end
        
        
        function updateState(self,x)
            % Only single-integrator dynamics right now.
            numPositionStates = numel(self.initialPosition);
            self.position = x(1:numPositionStates);

            self.state = self.position;
            
        end
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%                  MAIN                 %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [r_dot, data] = main(self, u)
             % MAIN - contains the ODE
             r_dot = u;
             
             data.r = reshape(self.position,3,[]);
             data.v = reshape(r_dot,3,[]);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end
