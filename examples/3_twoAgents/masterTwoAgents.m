function data = masterTwoAgents(t,nodes)

    % True position, velocity, accel
    r1 = nodes.agent1.outPosition; 
    r2 = nodes.agent2.outPosition;
    v1 = nodes.agent1.outVelocity;
    v2 = nodes.agent2.outVelocity;
    
    % UWB distance measurements. Cheating, this could be its own node.
    d_12 = norm(r1 - r2);
    
    % Input to the controllers
    nodes.agent1controller.r_zw_a = r1;
    nodes.agent1controller.r_21_a = (r2 - r1);
    nodes.agent1controller.y_UWB = d_12;
    nodes.agent2controller.r_zw_a = r2;
    nodes.agent2controller.r_21_a = (r1 - r2);
    nodes.agent2controller.y_UWB = d_12;
    
    % Control effort of each agent
    u1 = nodes.agent1controller.outControlEffort;
    u2 = nodes.agent2controller.outControlEffort;
    
    % Input to the dynamics
    nodes.agent1.inControlEffort = u1;
    nodes.agent2.inControlEffort = u2;
    
    % Data that we want
    data.r1 = r1;
    data.r2 = r2;
    data.u1 = u1;
    data.u2 = u2;
    data.dist = d_12;
end