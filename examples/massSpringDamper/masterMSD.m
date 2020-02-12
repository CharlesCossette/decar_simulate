% masterMSD  - MASTER for mass spring damper examples
%
% The MASTER is the "high level" ODE file which is directly called by the
% ode solver. The purpose of the master is to contain the interconnection
% of different nodes
%
% Note: you must have exactly these inputs and outputs in the function
% handle that is passed to the simulation object.
%
% Inputs:
% ---------
% t - [1 x 1] double
%       Current time. Passed by the ode solver.
% x - [n x 1] double
%       This will contain the states of ALL of your nodes, concatenated 
%       from top to bottom *in the order which the nodes were added*. 
%       Passed by the ode solver.
% nodes - [1 x 1] struct
%       A struct of node objects. Before master is called, the
%       node.updateState() function is called if it exists.
%       
% Outputs:
% ---------
% x_dot - [n x 1] struct 
%       Rate of change of x.
% data - [1 x 1] struct
%       Struct passing any additional interesting data.


function [x_dot, data] = masterMSD(t,x,nodes)
    
    % Read position and velocity. Here we can read directly from the node
    % instead of extracting from x because we have written an updateState()
    % function for the dynamics node.
    r = nodes.dynamics.position;
    v = nodes.dynamics.velocity;

    % Compute control effort by calling some function from controller node.
    [u, data_controller] = nodes.controller.computeEffort(r,v);
    
    % Compute acceleration by calling some function from the dynamics node.
    [v_dot, data_dynamics] = nodes.dynamics.computeAccel(u);
    
    % Send state rate of change
    x_dot = [v; v_dot];
    
    % Concatenate structs from different nodes into a single data struct.
    data = catstruct(data_dynamics, data_controller);
end