% MASS SPRING DAMPER EXAMPLE in DISCRETE TIME
% This is the "main" file for simple simulation of a PD controller
% controlling a mass-spring-damper system using this framework. 


% Create discrete time simulation object
sim = DiscreteSimulation();
sim.timeSpan = [0, 100];

% Add controller node, arbitrarily named 'controller'.
sim.addNode(ControllerNodeDiscreteMSD(),'controller',100)

% Add dynamics node, arbitrarily named 'dynamics'.
sim.addNode(DynamicsNodeDiscreteMSD(),'dynamics',200)

% Run sim, output data stored in a struct
tic
data = sim.run()
toc

% Graph shows how all the nodes are connected
sim.showGraph()
