%% Test 1 - MSD comparison with ODE45
% Parameters and conditions
params.m = 5;
params.c = 1;
params.k = 0.5;
params.k_p = 3;
params.k_d = 2;
x0 = [5;0];
tSpan = linspace(0,10,100);

% Run using ODE45
[t,x] = ode45(@(t,x) MSDODE(t,x,params),tSpan,x0);

% Run using custom framework
sim = ContinuousSimulation();
sim.odeSolver = 'ode45';
sim.timeSpan = tSpan;
dyn = DynamicsNodeMSD();
dyn.mass = params.m;
dyn.dampingConstant = params.c;
dyn.springConstant = params.k;
dyn.initialPosition = x0(1);
dyn.initialVelocity = x0(2);
sim.addNode(dyn,'dynamics')
cont = ControllerNodeMSD();
cont.k_p = params.k_p;
cont.k_d = params.k_d;
sim.addNode(cont,'controller')
sim.masterFunction = @masterMSD;
data = sim.run();

% Assert outputs are exactly the same.
assert(all(x(:,1).' == data.state(1,:)))
assert(all(x(:,2).' == data.state(2,:)))
plot(data.t,data.state(1,:),t,x(:,1).','LineWidth',2)
grid on
legend('Custom simulator','ode45')
xlabel('Time (s)')
ylabel('Position (m)')
title('Test 1: Comparison with ODE45')

function x_dot = MSDODE(t,x,params)
% Simple mass spring damper with PD controller
m = params.m;
c = params.c;
k = params.k;
k_p = params.k_p;
k_d = params.k_d;

r = x(1);
r_dot = x(2);
u = k_p*(0 - r) + k_d*(0 - r_dot);
r_ddot = (1/m)*(u - k*r - c*r_dot);
x_dot = [r_dot; r_ddot];
end