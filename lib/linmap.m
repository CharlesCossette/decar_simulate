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
output = ((c+d) + (d-c)*((2*x - (a+b))/(b-a)))/2;
end