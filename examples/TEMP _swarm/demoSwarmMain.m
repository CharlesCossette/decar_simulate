
% Create sim object
sim = ContinuousSimulation();

% Load Dynamics node
%
% Here you can see that you can instantiate the class first, modify some
% properties, and then add the node.
dyn = demoSwarmDynamics(4);
dyn.initialPosition = [[12;12;4],[-50;20;-1],[4;5;1],[-40;-10;-4]];
sim.addNode(dyn,'dynamics');

% Load Controller node
sim.addNode(demoSwarmController(4),'controller');

% Load master
sim.masterFunction = @demoSwarmMaster;

% Run sim
sim.timeSpan = linspace(0,10,100);
data = sim.run();

% Plot
plot(data.t, data.state)
grid on
xlabel('Time (s)')
ylabel('Positions')