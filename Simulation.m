classdef Simulation < handle
    % Generic continuous simulation class for any architecture of nodes.
    % TODO - event functions.
    % TODO - add more solvers
    
    properties
        masterFunction
        nodes
        timeSpan
        odeSolver
        odeOptions
    end
    
    methods
        function self = Simulation()
            % Constructor
            self.odeSolver = 'ode45';
            self.odeOptions = odeset();
            self.timeSpan = linspace(0,10,100);
        end
        
        function addNode(self, node, label)
            % Add node to list of nodes
            % TODO - automatically index nodes if label is repeated
            self.nodes.(label) = node;
        end
        
        function data = run(self)
            % Run simulation by numerically integrating ODE
            % TODO - add more ODE solvers
            
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
            
            data = self.getSimData(t, x, @(t,x) self.masterFunction(t,x,self));
            
            
        end
        
        function x0 = getInitialConditions(self)
            % Retrieve initial conditions of all nodes.
            x0 = [];
            nodeNames = fieldnames(self.nodes);
            numNodes = numel(nodeNames);
            for lv1 = 1:numNodes
                x0 = [x0;self.nodes.(nodeNames{lv1}).initialCondition()];
            end
            
            % NEED TO RECORD NUMBER OF STATES PER NODE.
            % Have inside the node?
        end
        
        function data = getSimData(~,t,x,masterFunc)
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
            end
            
            % Squeeze to eliminate redundant dimensions.
            dataNames = fieldnames(data);
            for lv1 = 1:numel(dataNames)
                data.(dataNames{lv1}) = squeeze(data.(dataNames{lv1}));
            end
        end
        
        function updateNodeStates(self,x)
            nodeNames = fieldnames(self.nodes);
            
            for lv1 = 1:length(nodeNames)
                numStates = self.nodes.(nodeNames{lv1}).numStates;
                self.nodes.(nodeNames{lv1}).updateState(x(1:numStates));
                x = x(numStates + 1:end);
            end
        end   
                
    end
end

