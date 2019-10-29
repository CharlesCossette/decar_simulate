
sim = Simulation();

% Load Dynamics node
sim.addNode(SwarmDynamics(4),'dynamics');

% Load Controller node
sim.addNode(SwarmController1(4),'controller');

% Load master
sim.masterFunction = @masterSwarmControl1;

% Run sim
sim.timeSpan = linspace(0,10,100);
data = sim.run();

% Plot
plot(data.t, data.state)