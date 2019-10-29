function [x_dot, data] = masterSwarmControl1(t,x,sim)
    
    sim.updateNodeStates(x);
    
    % Get specific state of interest.
    r = sim.nodes.dynamics.position;
    
    
    [u, dataController] = sim.nodes.controller.main(r);
    
    [r_dot, dataDynamics] = sim.nodes.dynamics.main(u);
    
    
    
    x_dot = r_dot;
    
    data = catstruct(dataController, dataDynamics);
    
end
    