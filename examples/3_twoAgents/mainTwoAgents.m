

sim = DiscreteSimulation();

% Add two agents' dynamics
% Customize properties, then add the nodes.
agent1 = SingleIntegratorAgent();
agent1.position = [10;0.1;0.1];
agent2 = SingleIntegratorAgent();
agent2.position = [-10;-0.1;-0.1];

sim.addNode(agent1,'agent1',1000);
sim.addNode(agent2,'agent2',1000);

% Add two agents' controllers
% Customize properties, then add the nodes.
agent1controller = AgentControllerv1();
agent1controller.r_des = [-10;0;0];
agent2controller = AgentControllerv1();
agent2controller.r_des = [10;0;0];

sim.addNode(agent1controller,'agent1controller',1000);
sim.addNode(agent2controller,'agent2controller',1000);

% Add master
sim.masterFunction = @masterTwoAgents;

% Run simulation
data = sim.run()

%% Plot
plotTwoAgents(data)