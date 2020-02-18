function data = masterTwoAgents(t,nodes)

    % True position, velocity, accel
    r1 = nodes.agent1.position; 
    r2 = nodes.agent2.position;
    
    % UWB distance measurements. Cheating, this could be its own node.
    dist_12 = norm(r1 - r2);
    
    % Compute control effort of each agent
    u1 = nodes.agent1controller.computeEffort(r1,(r2 - r1), dist_12);
    u2 = nodes.agent2controller.computeEffort(r2,(r1 - r2), dist_12);
    
    % Evaluate dynamics of each agent
    nodes.agent1.computeVelocity(u1);
    nodes.agent2.computeVelocity(u2);
    
    % Data that we want
    data.r1 = r1;
    data.r2 = r2;
    data.u1 = u1;
    data.u2 = u2;
    data.dist = dist_12;
end