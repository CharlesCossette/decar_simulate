%% Test - Asynchoronous MSD comparison with direct for loop
% The controller runs at half the frequency as the dynamics.
% Parameters and conditions
params.m = 5;
params.c = 1;
params.k = 0.5;
params.k_p = 3;
params.k_d = 2;
x0 = [5;0];
tSpan = [0 3];
freq = 10;
contFreq = freq/10;
% Run manually in discrete time
N = (tSpan(2) - tSpan(1))*freq + 1;
x = x0;
xStore = zeros(length(x0)+1,N);
tStore = zeros(N,1);
dt = 1/freq;
t = 0;

for lv1 = 1:N

    % Simple mass spring damper with PD controller
    m = params.m;
    c = params.c;
    k = params.k;
    k_p = params.k_p;
    k_d = params.k_d;

    r = x(1);
    r_dot = x(2);

    % Stupid float rounding errors.
    if abs(mod(t,(1/(contFreq)))) < 1e-10 || abs(abs(mod(t,(1/(contFreq)))) - (1/(contFreq))) < 1e-10
        u = k_p*(0 - r) + k_d*(0 - r_dot);
    else
        stop = 1;
    end
    r_ddot = (1/m)*(u - k*r - c*r_dot);
    x_dot = [r_dot; r_ddot];

    
    tStore(lv1) = t;
    xStore(:,lv1) = [x;u];
    t = t + dt;
    x = x + dt*x_dot;

end

% Run using custom framework, controller at 50 Hz, dynamics at 100 Hz
sim = DiscreteSimulation();
sim.timeSpan = tSpan;
cont = ControllerNodeDiscreteMSD();
cont.k_p = params.k_p;
cont.k_d = params.k_d;
dyn = DynamicsNodeDiscreteMSD();
dyn.mass = params.m;
dyn.dampingConstant = params.c;
dyn.springConstant = params.k;
dyn.position = x0(1);
dyn.velocity = x0(2);
% TODO: order nodes are added is important.
sim.addNode(dyn,'dynamics',freq)
sim.addNode(cont,'controller',contFreq)
data = sim.run();

% Plot as visual check - position
figure(1)
stairs(tStore,xStore(1,:).','LineWidth',2)
hold on
stairs(data.dynamics_update.t, data.dynamics_update.r,'LineWidth',2)
hold off
grid on
xlabel('Time (s)')
ylabel('Position (m)')
legend('Direct for-loop','decar-simulate')

% Plot as visual check - control effort
figure(2)
stairs(tStore,xStore(3,:).','LineWidth',2)
hold on
stairs(data.controller_update.t, data.controller_update.u,'LineWidth',2)
hold off
grid on
xlabel('Time (s)')
ylabel('Position (m)')
legend('Direct for-loop','decar-simulate')


% Assert outputs are exactly the same.
% Small floating point errors cause a tiny discrepancy
assert(all(abs(tStore - data.dynamics_update.t) < 1e-13))
assert(all(abs(xStore(1,:).' - data.dynamics_update.r) < 1e-13))
assert(all(abs(xStore(2,:).' - data.dynamics_update.v) < 1e-13))
