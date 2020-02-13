function data = masterDiscreteMSD(t,nodes)
% MASTER - the master is called asynchronously at a very high freqency. It
% is called just before any of the nodes get updated.
%
% All the interconnections should be done by reading and writing to the
% nodes' class properties, and using the update() function to
% propagate things forward in time.
%
% The output of this function is a mandatory data struct. The simulator
% will take care of accumulating all this data at each time step and sends
% the result as the output of the simulation.
%
% You should NOT have updateState() be called in this function, as it is
% called at the regulated intervals by the simulator!

    r = nodes.dynamics.position;
    v = nodes.dynamics.velocity;
    
    u = nodes.controller.computeEffort(r,v);
    
    a = nodes.dynamics.computeAccel(u);
    
    data.r = r;
    data.v = v;
    data.a = a;
    data.u = u;
end