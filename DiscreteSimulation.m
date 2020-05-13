classdef DiscreteSimulation < handle
    %DISCRETESIMULATION class for running multiple nodes in parallel, at
    % different frequencies. When you run a simulation with this class, it
    %
    % 1) Checks to see what node needs to be updated next, and then
    %    updates that node by running node.update(t) function.
    % 2) Stores any data returned by the node.update(t) function.
    %
    % This continuously occurs, advancing the simulator time to the next
    % node update, until we reach the user provided end time.
    
    properties
        nodes
        nodeFrequencies % This will eventually get removed
        nodeListeners % To be replaced
        timeSpan
        executables
        frequencies
        names
        execData
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
            % Add node to list of nodes.
            % Inputs:
            % --------
            % node: Object
            %       An instantiation of a a specific node object.
            %
            % nodeName: string
            %       specific name to call that node, can be different
            %       from the class name.
            %
            % nodeFreq: int
            %       node frequency in Hz. Can be different from all
            %       the other nodes.
            
            self.nodes.(nodeName) = node;
            self.nodeFrequencies.(nodeName) = nodeFreq;
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
            
            % Create executables (all asynchronous functions)
            self.createExecutables()            
            
            % Get node frequencies
            % store in a matrix instead of struct.
            nodeFreq = self.frequencies;
            
            % Start and end times
            tStart = self.timeSpan(1);
            tEnd = self.timeSpan(end);
            
            % Column matrix stores the next time that node should be
            % updated. Initialize all to tStart
            nodeNextUpdateTimes = tStart*ones(length(nodeFreq),1);
            t = tStart;
            
            
            % Run all executables once to initialize everything.
            for lv1 = 1:length(self.executables)
                exec = self.executables{lv1};
                % Need to try-catch because the executable might
                % not have any output arguments, in which case it
                % would throw a "Too many output arguments" error. 
                % TODO.. there must be a better way to do this.
                try
                    [~] = exec(t);
                catch
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
                        exec = self.executables{lv1};
                       
                        % Need to try-catch because the executable might
                        % not have any output arguments, in which case it
                        % would throw a "Too many output arguments" error. 
                        % TODO.. there must be a better way to do this.
                        try
                            data_exec_k = exec(t);

                            % Append data
                            self.execData.(self.names{lv1}) = ...
                                self.appendSimData(t,data_exec_k, self.execData.(self.names{lv1}));
                        catch
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
            for lv1 = 1:length(self.executables)
                data_exec = self.execData.(self.names{lv1});
                dataNames = fieldnames(data_exec);
                for lv2 = 1:numel(dataNames)
                    data_exec.(dataNames{lv2}) = squeeze(data_exec.(dataNames{lv2}));
                end
                self.execData.(self.names{lv1}) = data_exec;
            end
            data = self.execData;
            
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
                            edgeTable = [edgeTable; {{nodeNames{lv3},nodeNames{lv1}},L.Source{:}.Name}];
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
            % TODO - ACTUALLY DO THIS SOON. Would seriously improve speed.
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
        
        function createExecutables(self)
            % Collects all the function handles that the user has returned
            % as desired asynchrousnous executables, along with the
            % frequencies at which to execute them.
            nodeNames = fieldnames(self.nodes);
            self.executables = {};
            self.frequencies = [];
            self.names = {};
            for lv1 = 1:length(nodeNames)
                % Add the update(t) function of each node as an executable.
                % TODO - we could remove the update() function altogether
                % now seeing as its just another executable.
                nodeName = nodeNames{lv1};
                node = self.nodes.(nodeName);
                execName = 'update';
                self.executables = [self.executables; {@node.update}];
                self.frequencies = [self.frequencies; self.nodeFrequencies.(nodeNames{lv1})];
                self.names = [self.names; [nodeName,'_',execName]];
                self.execData.([nodeName,'_',execName]) = struct();
                % Add any other user-specifed executables.
                % TODO - add user error checking
                if ismethod(self.nodes.(nodeName),'createExecutables')
                    [handles, freqs] = self.nodes.(nodeName).createExecutables();
                    for lv2 = 1:length(handles)
                        exec = handles{lv2};
                        freq = freqs(lv2);
                        execName = func2str(exec);
                        execName = erase(execName,'@(varargin)self.');
                        execName = erase(execName,'(varargin{:})');
                        self.executables = [self.executables; {exec}];
                        self.frequencies = [self.frequencies; freq];
                        self.names = [self.names; [nodeName,'_',execName]];
                        self.execData.([nodeName,'_',execName]) = struct();
                    end
                end
            end
        end
            
    end
end