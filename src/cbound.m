function output = cbound(x,x_min,x_max)
    % Continously differentiable saturation function!
    % For use in Runge-Kutta methods and similar.
    
    if x_min >= x_max
        error('max must be greater than min!')
    end

    p = 12;
    x = linmap(x,x_min,x_max,-1,1);
    output = x./(1 + x.^p).^(1/p);
    output = linmap(output,-1,1,x_min,x_max);
end
       
function output = linmap(x, fromMin, fromMax, toMin, toMax)
% function for linear mapping between two ranges
% Inputs:
% x \in [fromMin, fromMax]  - any matrix of values
% y \in [toMin, toMax]      - values of x translated and scaled linearly
% corresponding to the ranges.

a = fromMin;
b = fromMax;
c = toMin;
d = toMax;
output = ((c+d) + (d-c).*((2*x - (a+b))./(b-a)))/2;
end