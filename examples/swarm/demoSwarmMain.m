
sim = ContinuousSimulation();

% Load Dynamics node
sim.addNode(demoSwarmDynamics(4),'dynamics');

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