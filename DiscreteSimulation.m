classdef DiscreteSimulation < handle
    %DISCRETESIMULATION class for running multiple nodes in parallel, at
    % difference frequencies. When you run a simulation with this class, it
    %
    % 1) Checks to see what node needs to be updated next, and then
    %    updates that node by running node.update(t) function.
    % 2) Stores any data returned by the node.update(t) function.
    %
    % This continuously occurs, advancing the simulator time to the next
    % node update, until we reach the user provided end time.
    
    properties
        nodes
        nodeFrequencies
        nodeNumStates
        nodeData
        nodeListeners
        timeSpan
    end
    properties (Access = private)
        waitbarHandle
    end
    
    methods
        function self = DiscreteSimulation()
            % Constructor
            self.timeSpan = [0 10];
        end
        
        function addNode(self, node, nodeName, nodeFreq)
            % Add node to list of nodes
            self.nodes.(nodeName) = node;
            self.nodeFrequencies.(nodeName) = nodeFreq;
            self.nodeData.(nodeName) = struct();
        end
        
        function data = run(self)
            % RUN SIMULATION
            % This function takes care of looping through the time span and
            % updating the nodes at each of their respective frequencies.
            
            % Close all open waitbars
            F = findall(0,'type','figure','tag','TMWWaitbar');
            delete(F)
            
            % Create waitbar
            self.waitbarHandle = waitbar(0,'Simulation In Progress');
            
            % Create listeners
            self.createListeners()
            
            % Get node frequencies
            % store in a matrix instead of struct.
            nodeNames = fieldnames(self.nodes);
            nodeFreq = zeros(length(nodeNames),1);
            for lv1 = 1:length(nodeNames)
                nodeFreq(lv1) = self.nodeFrequencies.(nodeNames{lv1});
            end
            
            % Start and end times
            tStart = self.timeSpan(1);
            tEnd = self.timeSpan(end);
            
            % Column matrix stores the next time that node should be
            % updated. Initialize all to tStart
            nodeNextUpdateTimes = tStart*ones(length(nodeFreq),1);
            t = tStart;
            
            
            % Check if it is time to update eacsh node.
            for lv1 = 1:length(nodeNames)
                % Update node state
                node = self.nodes.(nodeNames{lv1});
                if ismethod(node,'update')
                    [~] = node.update(t);
                end
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%
            while t <= tEnd
                
                % Check if it is time to update each node.
                % Note: a small tolerance of 1e-14 is used due to
                % occaisional rounding errors.
                for lv1 = 1:length(nodeNextUpdateTimes)
                    if abs(t - nodeNextUpdateTimes(lv1)) < 1e-14
                        
                        % Update node state
                        node = self.nodes.(nodeNames{lv1});
                        if ismethod(node,'update')
                            data_node_k = node.update(t);
                            
                            % Append data
                            self.nodeData.(nodeNames{lv1}) = ...
                                self.appendSimData(t,data_node_k, self.nodeData.(nodeNames{lv1}));
                        end
                        
                        % Update next time to run update for this node.
                        nodeNextUpdateTimes(lv1) = nodeNextUpdateTimes(lv1) + 1/nodeFreq(lv1);
                    end
                end
                
                % Update waitbar
                waitbar(t/tEnd,self.waitbarHandle);
                
                % Soonest update time
                tNext = min(nodeNextUpdateTimes);
                
                % Go to soonest update time
                t = tNext;
            end
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Final bit of post-processing
            % Squeeze to eliminate redundant dimensions.
            for lv1 = 1:length(nodeNames)
                data_node = self.nodeData.(nodeNames{lv1});
                dataNames = fieldnames(data_node);
                for lv2 = 1:numel(dataNames)
                    data_node.(dataNames{lv2}) = squeeze(data_node.(dataNames{lv2}));
                end
                self.nodeData.(nodeNames{lv1}) = data_node;
            end
            data = self.nodeData;
            
            % Close waitbar
            close(self.waitbarHandle)
        end
        
        function showGraph(self)
            if isempty(self.nodeListeners)
                self.createListeners();
            end
            edgeTable = table([  ],[],'VariableNames',{'EndNodes' 'Label'});
            nodeNames = fieldnames(self.nodes);
            % Go through all the nodes
            for lv1 = 1:numel(nodeNames)
                listeners = self.nodeListeners.(nodeNames{lv1});
                % Go through all the listeners to that node
                for lv2 = 1:numel(listeners)
                    L = listeners(lv2);
                    % Go through all the nodes again to find out which node
                    % it is listening to
                    for lv3 = 1:numel(nodeNames)
                        obj = L.Object{:};
                        if obj == self.nodes.(nodeNames{lv3})
                            edgeTable = [edgeTable;{{nodeNames{lv3},nodeNames{lv1}},L.Source{:}.Name}];
                        end
                    end
                    
                end
            end
            
            G = digraph(edgeTable);
            if numedges(G) > 0
                p = plot(G,'EdgeLabel',G.Edges.Label);
                p.Marker = 's';
                p.MarkerSize = 7;
                p.NodeColor = 'r';
                p.ArrowSize = 15;
            else
                disp('No listeners in this simulation!')
            end
        end
        
    end
    
    methods (Access = private)
        function data = appendSimData(~,t,data_k,data)
            % Get all the field names from the sol_data struct.
            % TODO - inefficient, memory not preallocated.
            data_k.t = t;
            dataNames_k = fieldnames(data_k);
            
            % Each field should contain only 1 value, so loop and keep
            % combining into a final data struct.
            for lv2 = 1:numel(dataNames_k)
                if isfield(data, dataNames_k{lv2})
                    % Check if there is a field already in self.data
                    
                    % If a field contains a matrix, append in the
                    % 3rd dimension. Generalized to N dimensions.
                    N = ndims(data_k.(dataNames_k{lv2}));
                    data.(dataNames_k{lv2}) = cat(N + 1, data.(dataNames_k{lv2}),...
                        data_k.(dataNames_k{lv2}));
                else
                    % Otherwise create the field.
                    data.(dataNames_k{lv2}) = [data_k.(dataNames_k{lv2})];
                end
            end
            
        end
        function createListeners(self)
            % Run the createListeners method of all classes.
            % If an output argument is returned, store it to create the
            % interconnection graph.
            nodeNames = fieldnames(self.nodes);
            self.nodeListeners = struct();
            for lv1 = 1:length(nodeNames)
                try
                    varargout = self.nodes.(nodeNames{lv1}).createListeners(self.nodes);
                    self.nodeListeners.(nodeNames{lv1}) = varargout;
                catch
                    self.nodeListeners.(nodeNames{lv1}) = [];
                end
            end
        end
    end
end