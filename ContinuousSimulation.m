classdef ContinuousSimulation < handle
    % Generic continuous simulation class for any architecture of nodes.
    % TODO - event functions.
    % TODO - eliminate the need to carefully construct x_dot with the
    % correct ordering.
    % TODO - add node superclass (might not be necessary, obvious what to
    % do if you receive no initial condition).
    
    properties
        masterFunction
        nodes
        nodeNumStates
        timeSpan
        odeSolver
        odeOptions
    end
    properties (Access = private)
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
            % TODO - add ode15s as a solver
            
            self.waitbarHandle = waitbar(0,'Simulation In Progress');
            if strcmp(self.odeSolver,'ode45')
                [t,x] = ode45(@(t,x) self.masterWrapper(t,x),...
                                     self.timeSpan,...
                                     self.getInitialConditions(),...
                                     self.odeOptions);
            elseif strcmp(self.odeSolver,'ode113')
                [t,x] = ode113(@(t,x) self.masterWrapper(t,x),...
                                      self.timeSpan,...
                                      self.getInitialConditions(),...
                                      self.odeOptions);   
            elseif strcmp(self.odeSolver,'ode4')
                [t,x] = ode4(@(t,x) self.masterWrapper(t,x),...
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
            % Loops through all the nodes and runs the initialCondition()
            % method if it exists. This method also records the number of
            % states present in each node, by reading the size of the
            % return value from the initialCondition() method.
            
            x0 = [];
            nodeNames = fieldnames(self.nodes);
            numNodes = numel(nodeNames);
            for lv1 = 1:numNodes
                if ismethod(self.nodes.(nodeNames{lv1}),'initialCondition')
                    x0_node = self.nodes.(nodeNames{lv1}).initialCondition();
                
                    % Error checking for initial condition.
                    if size(x0_node,2) > 1
                        error(['Error in initial conditions of ',...
                                nodeNames{lv1},...
                               '. Must be column matrix']);
                    end

                    self.nodeNumStates.(nodeNames{lv1}) = length(x0_node);
                    x0 = [x0;x0_node];
                end
            end
            
        end
        
        function updateNodeStates(self,x)
            % Loops through all the nodes and runs the updateState(x)
            % method if it exists.
            nodeNames = fieldnames(self.nodes);
            
            for lv1 = 1:length(nodeNames)
                if ismethod(self.nodes.(nodeNames{lv1}),'updateState')
                    numStates = self.nodeNumStates.(nodeNames{lv1});
                    self.nodes.(nodeNames{lv1}).updateState(x(1:numStates));
                    x = x(numStates + 1:end);
                end
            end
        end
        
    end
    methods (Access = private)
        
        function [x_dot, data] = masterWrapper(self,t,x)
            % Update Node states
            self.updateNodeStates(x);
            % Call master
            [x_dot, data] = self.masterFunction(t,x,self.nodes);  
            % Update waitbar
            waitbar(t/self.timeSpan(end),self.waitbarHandle);
        end
        
        function data = getSimData(self,t,x,masterFunc)
            % Get sim data from second output of master.
            % TODO - inefficient appending, find solution.
            
            % Initialize
            data = [];
            % Store time data.
            data.t = t;
            % Store raw state, just in case.
            data.state = x.';
            
            x_dot = zeros(size(x))';
            for lv1 = 1:size(x,1)
                % Feed solution back into master to get the data struct
                % from the second output.
                [x_dot(:,lv1), sol_data] = masterFunc(t(lv1), x(lv1,:)');
                
                % Get all the field names from the sol_data struct.
                dataNames = fieldnames(sol_data);
                % Each field should contain only 1 value, so loop and keep
                % combining into a final data struct.
                for lv2 = 1:numel(dataNames)
                    if isfield(data, dataNames{lv2})
                        % If a field contains a matrix, append in the
                        % 3rd dimension. Generalized to N dimensions.
                        N = ndims(sol_data.(dataNames{lv2}));
                        data.(dataNames{lv2}) = cat(N+1, data.(dataNames{lv2}),...
                                                         sol_data.(dataNames{lv2}));
                    else
                        data.(dataNames{lv2}) = [sol_data.(dataNames{lv2})];
                    end
                end
                waitbar(lv1/size(x,1),self.waitbarHandle,'Extracting Data');
            end
            data.stateRate = x_dot;
            
            % Squeeze to eliminate redundant dimensions.
            dataNames = fieldnames(data);
            for lv1 = 1:numel(dataNames)
                data.(dataNames{lv1}) = squeeze(data.(dataNames{lv1}));
            end
            
            
        end
                
    end
end

