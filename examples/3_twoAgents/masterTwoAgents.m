function data = masterTwoAgents(t,nodes)

    % True position, velocity, accel
    r1 = nodes.agent1.position; 
    r2 = nodes.agent2.position;
    v1 = nodes.agent1.velocity;
    v2 = nodes.agent2.velocity;
    a1 = nodes.agent1.accel; 
    a2 = nodes.agent2.accel;
    
    % Get sensor measurements
    y1 = nodes.agent1accel.measurement(a1); 
    y2 = nodes.agent2accel.measurement(a2);
    
    % UWB distance measurements. Cheating, thus could be its own node.
    dist_12 = norm(r1 - r2);
    
    % Compute control effort of each agent
    u1 = nodes.agent1controller.computeEffort(r1,v1,y1, dist_12);
    u2 = nodes.agent2controller.computeEffort(r2,v2,y2, dist_12);
    
    % Evaluate dynamics of each agent
    nodes.agent1.computeAccel(u1);
    nodes.agent2.computeAccel(u2);
    
    % Data that we want
    data.r1 = r1;
    data.r2 = r2;
    data.u1 = u1;
    data.u2 = u2;
    data.dist = dist_12;
    data.y_accel_1  = y1;
    data.y_accel_2 = y2;
end