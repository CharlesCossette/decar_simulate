function plotTwoAgents(data)
figure(1)
plot3(data.agent1.r(1,:), data.agent1.r(2,:), data.agent1.r(3,:),'LineWidth',2)
hold on
plot3(data.agent2.r(1,:), data.agent2.r(2,:), data.agent2.r(3,:),'LineWidth',2)
hold off
axis vis3d
axis equal
xlabel('$x$ (m)','interpreter','latex','FontSize',14)
ylabel('$y$ (m)','interpreter','latex','FontSize',14)
zlabel('$z$ (m)','interpreter','latex','FontSize',14)
grid on
title('Trajectory of two agents heading into each other')

figure(2)
plot(data.agent1.t, data.agent1.r,'LineWidth',2)
hold on
plot(data.agent2.t, data.agent2.r,'LineWidth',2)
hold off
grid on
xlabel('Time (s)','interpreter','latex','FontSize',14)
ylabel('$r_{ai}$ (m)','interpreter','latex','FontSize',14)
title('Agent 1 and 2 Position')
legend('agent1 x','agent1 y', 'agent1 z','agent2 x', 'agent2 y', 'agent2 z')

%figure(3)
% plot(data.t, data.dist,'LineWidth',2)
% hold on
% plot([data.t(1) data.t(end)],[3 3],'LineStyle','--','LineWidth',2)
% hold off
% grid on
% xlabel('Time (s)')
% ylabel('d (m)')
% title('Distance between agents')

figure(4)
plot(data.agent1controller.t, data.agent1controller.u,'LineWidth',2)
grid on
xlabel('Time (s)','interpreter','latex','FontSize',14)
ylabel('$\mathbf{u}$','interpreter','latex','FontSize',14)
title('Control Effort')

end
