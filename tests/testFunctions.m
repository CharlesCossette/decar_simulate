%% Test - cbound (continuous saturation function)
x = linspace(-4,3,100);
x_max = 1;
x_min = -1;
y1 = cbound(x,x_min,x_max);
y2 = min(max(x,x_min),x_max);

figure(1)
plot(x,y1,x,y2,'LineWidth',2)
xlabel('x')
ylabel('y')
axis equal
grid on
legend('Continuous','Ideal Discontinuous Saturation')