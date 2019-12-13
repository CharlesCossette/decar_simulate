function [t_span, yout] = ode4(F,t_span,y0,options)
   % ODE4  Classical Runge-Kutta ODE solver.
   %   yout = ODE4(F,t0,h,tfinal,y0) uses the classical
   %   Runge-Kutta method with fixed step size h on the interval
   %      t0 <= t <= tfinal
   %   to solve
   %      dy/dt = F(t,y)
   %   with y(t0) = y0.

   %   Copyright 2014 - 2015 The MathWorks, Inc.
      t0 = t_span(1);
      tfinal = t_span(length(t_span));
      h = t_span(2) - t_span(1);
      
      y = y0;
      yout = y';
      for t = t0 : h : tfinal-h
         s1 = F(t,y);
         s2 = F(t+h/2, y+h*s1/2);
         s3 = F(t+h/2, y+h*s2/2);
         s4 = F(t+h, y+h*s3);
         y = y + h*(s1 + 2*s2 + 2*s3 + s4)/6;
         yout = [yout; y'];
      end