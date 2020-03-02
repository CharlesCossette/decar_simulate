clear

sim = DiscreteSimulation();

% Add two agents' dynamics
% Customize properties, then add the nodes.
% AGENT 1 Dynamics
agent1 = SingleIntegratorAgent(1);
agent1.position = [10;1;0.5];
sim.addNode(agent1,'agent1',1000);

% AGENT 2 Dynamics
agent2 = SingleIntegratorAgent(2);
agent2.position = [-10;-1;-0.5];
sim.addNode(agent2,'agent2',1000);

% Add two agents' controllers
agent1controller = AgentControllerv1(1);
agent1controller.r_zrw_a = [-10;1;0.5];
sim.addNode(agent1controller,'agent1controller',1000);

agent2controller = AgentControllerv1(2);
agent2controller.r_zrw_a = [10;-1;0.5];
sim.addNode(agent2controller,'agent2controller',1000);

% Add two agents' relative position sensor
relpos1 = RelativePositionSensor(1);
sim.addNode(relpos1,'relPosSensor1',1000)
relpos2 = RelativePositionSensor(2);
sim.addNode(relpos2,'relPosSensor2',1000)

% Run simulation
data = sim.run();

%% Plot
plotTwoAgents(data)
