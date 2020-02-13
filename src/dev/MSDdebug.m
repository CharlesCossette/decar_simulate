
m = 4;
k = 0.4;
c = 0.1;

r_0 = 5;
v_0 = 0;

k_p = -5;
k_d = -5.5;


tStart = 0;
tEnd = 10;
freq = 100;

% Initialize
r = r_0;
v = v_0;
tOld = tStart;
for t = tStart:(1/freq):tEnd
    u = k_p*r + k_d*v;
    a = (1/m)*(u - k*r - c*v);
    
    dt = t-tOld;
    r = r + dt*v;
    v = v + dt*a;
    tOld = t;
end