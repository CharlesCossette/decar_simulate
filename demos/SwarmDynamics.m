classdef SwarmDynamics < handle 
    % Only single-integrator dynamics right now.
    properties
        numAgents
        numStates
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
        function self = SwarmDynamics(numAgents)
            % Constructor
            self.numAgents = numAgents;
        end
             
        function x0 = initialCondition(self)
            % Initial conditions
            r0 = normrnd(0,10,[3, self.numAgents]);
            v0 = zeros(size(r0));
            self.initialPosition = r0(:);
            self.initialVelocity = v0(:);
            x0 = self.initialPosition;
            self.numStates = length(x0);       
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
