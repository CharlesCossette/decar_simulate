function [x_dot, data] = demoSwarmMaster(t,x,nodes)
    
    % Get specific state of interest.
    r = nodes.dynamics.position;
    
    [u, dataController] = nodes.controller.main(r);
    
    [r_dot, dataDynamics] = nodes.dynamics.main(u);
    
    x_dot = r_dot;
    
    data = catstruct(dataController, dataDynamics);
    
end
    