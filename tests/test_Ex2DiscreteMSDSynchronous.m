%% Test - Synchoronous MSD comparison with direct for loop
% Parameters and conditions
params.m = 5;
params.c = 1;
params.k = 0.5;
params.k_p = 3;
params.k_d = 2;
x0 = [5;0];
tSpan = [0 10];
freq = 100;

% Run manually in discrete time
N = (tSpan(2) - tSpan(1))*freq + 1;
x = x0;
xStore = zeros(length(x0),N);
tStore = zeros(N,1);
dt = 1/freq;
t = 0;
for lv1 = 1:N
    tStore(lv1) = t;
    xStore(:,lv1) = x;
    x = MSDEuler(dt,x,params);
    t = t + dt;
end

% Run using custom framework, each at 100 Hz
sim = DiscreteSimulation();
sim.timeSpan = [0 10];
cont = ControllerNodeDiscreteMSD();
cont.k_p = params.k_p;
cont.k_d = params.k_d;
sim.addNode(cont,'controller',freq)
dyn = DynamicsNodeDiscreteMSD();
dyn.mass = params.m;
dyn.dampingConstant = params.c;
dyn.springConstant = params.k;
dyn.position = x0(1);
dyn.velocity = x0(2);
sim.addNode(dyn,'dynamics',freq)
data = sim.run();

% Plot as visual check
plot(tStore,xStore(1,:).','LineWidth',2)
hold on
plot(data.t, data.r,'LineWidth',2)
hold off
grid on
xlabel('Time (s)')
ylabel('Position (m)')
legend('Direct for-loop','decar-simulate')

% Assert outputs are exactly the same.
% Small floating point errors cause a tiny discrepancy
assert(all(tStore == data.t))
assert(all(xStore(1,:).' - data.r < 1e-13))
assert(all(xStore(2,:).' - data.v < 1e-13))

function x_k1 = MSDEuler(dt,x_k,params)
% Simple mass spring damper with PD controller
m = params.m;
c = params.c;
k = params.k;
k_p = params.k_p;
k_d = params.k_d;

r = x_k(1);
r_dot = x_k(2);
u = k_p*(0 - r) + k_d*(0 - r_dot);
r_ddot = (1/m)*(u - k*r - c*r_dot);
x_dot = [r_dot; r_ddot];

x_k1 = x_k + dt*x_dot;
end