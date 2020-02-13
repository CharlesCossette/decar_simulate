% MASS SPRING DAMPER EXAMPLE in DISCRETE TIME
% This is the "main" file for simple simulation of a PD controller
% controlling a mass-spring-damper system using this framework. 


% Create discrete time simulation object
sim = DiscreteSimulation();

% Add controller node, arbitrarily named 'controller'.
sim.addNode(ControllerNodeDiscreteMSD(),'controller',100)

% Add dynamics node, arbitrarily named 'dynamics'.
sim.addNode(DynamicsNodeDiscreteMSD(),'dynamics',100)

% Add master as function handle.
sim.masterFunction = @masterDiscreteMSD;

% Run sim
data = sim.run()

