% MASS SPRING DAMPER EXAMPLE in CONTINUOUS TIME
% This is the "main" file for simple simulation of a PD controller
% controlling a mass-spring-damper system using this framework. 


% Create continuous time simulation object
sim = ContinuousSimulation();

% Add dynamics node, arbitrarily named 'dynamics'.
sim.addNode(DynamicsNodeMSD(),'dynamics')

% Add controller node, arbitrarily named 'controller'.
sim.addNode(ControllerNodeMSD(),'controller')

% Add master as function handle.
sim.masterFunction = @masterMSD;

% Run sim
data = sim.run()

