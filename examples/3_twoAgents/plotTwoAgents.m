function plotTwoAgents(data)
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
hold off
grid on
xlabel('Time (s)')
ylabel('r_i')
title('Agent 1 and 2 Position')
legend('agent1 x','agent1 y', 'agent1 z','agent2 x', 'agent2 y', 'agent2 z')

figure(3)
plot(data.t, data.dist,'LineWidth',2)
hold on
plot([data.t(1) data.t(end)],[3 3],'LineStyle','--','LineWidth',2)
hold off
grid on
xlabel('Time (s)')
ylabel('d (m)')
title('Distance between agents')

figure(4)
plot(data.t, data.y_accel_1)
grid on

end
