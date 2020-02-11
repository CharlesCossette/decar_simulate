classdef ContinuousSimulation < handle
    % Generic continuous simulation class for any architecture of nodes.
    % TODO - event functions.
    % TODO - add more solvers
    
    properties
        masterFunction
        nodes
        numNodeStates
        timeSpan
        odeSolver
        odeOptions
        waitbarHandle
    end
    
    methods
        function self = ContinuousSimulation()
            % Constructor - default settings
            self.odeSolver = 'ode45';
            self.odeOptions = odeset();
            self.timeSpan = linspace(0,10,100);
        end
        
        function addNode(self, node, nodeName)
            % Add node to list of nodes
            % TODO - automatically index nodes if label is repeated
            self.nodes.(nodeName) = node;
        end
        
        function data = run(self)
            % Run simulation by numerically integrating ODE
            % TODO - add more ODE solvers
            % TODO - add waitbar!
            self.waitbarHandle = waitbar(0,'Simulation In Progress');
            if strcmp(self.odeSolver,'ode45')
                [t,x] = ode45(@(t,x) self.masterFunction(t,x,self),...
                                     self.timeSpan,...
                                     self.getInitialConditions(),...
                                     self.odeOptions);
            elseif strcmp(self.odeSolver,'ode113')
                [t,x] = ode113(@(t,x) self.masterFunction(t,x,self),...
                                      self.timeSpan,...
                                      self.getInitialConditions(),...
                                      self.odeOptions);   
            elseif strcmp(self.odeSolver,'ode4')
                [t,x] = ode4(@(t,x) self.masterFunction(t,x,self),...
                                      self.timeSpan,...
                                      self.getInitialConditions(),...
                                      self.odeOptions);  
            else
                error('ODE solver not supported.')
            end
            
            
            data = self.getSimData(t, x, @(t,x) self.masterWrapper(t,x));
            
            close(self.waitbarHandle);
        end

        
        function x0 = getInitialConditions(self)
            % Retrieve initial conditions of all nodes.
            x0 = [];
            nodeNames = fieldnames(self.nodes);
            numNodes = numel(nodeNames);
            for lv1 = 1:numNodes
                x0_node = self.nodes.(nodeNames{lv1}).initialCondition();
                if size(x0_node,2) > 1
                    error(['Error in initial conditions of ',...
                            nodeNames{lv1},...
                           '. Must be column matrix']);
                end
                self.numNodeStates.(nodeNames{lv1}) = length(x0_node);
                x0 = [x0;x0_node];
                
            end
            
            % NEED TO RECORD NUMBER OF STATES PER NODE.
            % Have inside the node?
        end
        
        function updateNodeStates(self,x)
            % Loops through all the nodes and runs the updateState()
            % function.
            nodeNames = fieldnames(self.nodes);
            
            for lv1 = 1:length(nodeNames)
                numStates = self.numNodeStates.(nodeNames{lv1});
                self.nodes.(nodeNames{lv1}).updateState(x(1:numStates));
                x = x(numStates + 1:end);
            end
        end
        
    end
    methods (Access = private)
        
        function [x_dot, data] = masterWrapper(self,t,x)
            % Update Node states
            self.updateNodeStates(x);
            % Call master
            [x_dot, data] = self.masterFunction(t,x,self);  
            % Update waitbar
            waitbar(t/self.timeSpan(end),self.waitbarHandle);
        end
        
        
        

        
        function data = getSimData(self,t,x,masterFunc)
            % Get sim data from second output argument of master.
            
            % Initialize
            data = [];
            % Store time data.
            data.t = t;
            % Store raw state, just in case.
            data.state = x;
            
            % TODO - do something with x_dot? currently useless. Stored but
            % doing nothing.
            x_dot = zeros(size(x))';
            for lv1 = 1:size(x,1)
                [x_dot(:,lv1), sol_data] = masterFunc(t(lv1), x(lv1,:)');
                dataNames = fieldnames(sol_data);
                for lv2 = 1:numel(dataNames)
                    if isfield(data, dataNames{lv2})
                        N = ndims(sol_data.(dataNames{lv2}));
                        data.(dataNames{lv2}) = cat(N+1, data.(dataNames{lv2}), sol_data.(dataNames{lv2}));
                    else
                        data.(dataNames{lv2}) = [sol_data.(dataNames{lv2})];
                    end
                end
                waitbar(lv1/size(x,1),self.waitbarHandle,'Extracting Data');
            end
            
            % Squeeze to eliminate redundant dimensions.
            dataNames = fieldnames(data);
            for lv1 = 1:numel(dataNames)
                data.(dataNames{lv1}) = squeeze(data.(dataNames{lv1}));
            end
            
            
        end
                
    end
end

