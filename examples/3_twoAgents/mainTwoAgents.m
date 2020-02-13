

sim = DiscreteSimulation();

% Add two agents' dynamics
% Customize properties, then add the nodes.
agent1 = DoubleIntegratorAgent();
agent1.position = [10;0.1;0.1];
agent2 = DoubleIntegratorAgent();
agent2.position = [-10;-0.1;-0.1];

sim.addNode(agent1,'agent1',1000);
sim.addNode(agent2,'agent2',1000);

% Add two agents' controllers
% Customize properties, then add the nodes.
agent1controller = AgentControllerv1();
agent1controller.r_des = [-10;0;0];
agent2controller = AgentControllerv1();
agent2controller.r_des = [10;0;0];

sim.addNode(agent1controller,'agent1controller',100);
sim.addNode(agent2controller,'agent2controller',100);

% Add a sensor on each agent
sim.addNode(PointMassAccelerometer(),'agent1accel',1000);
sim.addNode(PointMassAccelerometer(),'agent2accel',1000);

% Add master
sim.masterFunction = @masterTwoAgents;

% Run simulation
data = sim.run()

%% Plot
plotTwoAgents(data)