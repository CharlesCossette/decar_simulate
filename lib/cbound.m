function output = cbound(x,x_min,x_max)
    if x_min >= x_max
        error('max must be greater than min!')
    end

    %output = h./(max + exp(-h*x)) + min;
    p = 12;
    x = linmap(x,x_min,x_max,-1,1);
    output = x./(1 + x.^p).^(1/p);
    output = linmap(output,-1,1,x_min,x_max);
end
        