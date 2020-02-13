

sim = DiscreteSimulation();

% Add two agents' dynamics
% Customize properties, then add the node.
agent1 = DoubleIntegratorAgent();
agent1.position = [10;0;0];
agent2 = DoubleIntegratorAgent();
agent2.position = [-10;0;0];
sim.addNode(agent1,'agent1',100);
sim.addNode(agent2,'agent2',100);

% Add two agents' controllers
% Customize properties, then add the node.
agent1controller = AgentControllerv1();
agent1controller.r_des = [-10;0;0];
agent2controller = AgentControllerv1();
agent2controller.r_des = [10;0;0];
sim.addNode(agent1controller,'agent1controller',100);
sim.addNode(agent2controller,'agent2controller',100);

% Add a sensor on each agent
sim.addNode(PointMassAccelerometer(),'agent1accel',100);
sim.addNode(PointMassAccelerometer(),'agent2accel',100);

% Add master
sim.masterFunction = @masterTwoAgents;

% Run simulation
data = sim.run()

%% Plot
figure(1)
plot3(data.r1(1,:), data.r1(2,:), data.r1(3,:),'LineWidth',2)
hold on
plot3(data.r2(1,:), data.r2(2,:), data.r2(3,:),'LineWidth',2)
hold off
axis vis3d
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
grid on

figure(2)
plot(data.t, data.r1,'LineWidth',2)
hold on
plot(data.t, data.r2,'LineWidth',2)
grid on
xlabel('Time (s)')
ylabel('r_i')
title('Agent 1 and 2 Position')
legend('agent1 x','agent1 y', 'agent1 z','agent2 x', 'agent2 y', 'agent2 z')