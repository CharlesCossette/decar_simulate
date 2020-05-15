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
        nodeTransferors
        timeSpan
        executables
        frequencies
        names
        execData
    end
    properties (Access = private)
        waitbarHandle
        hasOutput
        execNodes
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
            
            % Clear old data if any
            self.execData = struct();
            
            % Create waitbar
            self.waitbarHandle = waitbar(0,'Simulation In Progress');
            
            % Create listeners
            self.createListeners()
            
            % Create transferors
            self.createTransferors()
            
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
            % Check and record if the function has an output.
            self.hasOutput = false(length(self.executables),1);
            iterNode       = ''; 
            for lv1 = 1:length(self.executables)
                clear ans
                exec = self.executables{lv1};
                
                % Run transferor
                % First, check if any other nodes have been updated since
                % the last time this node was updated.
                if ~strcmp(iterNode,self.execNodes{lv1})
                    iterNode = self.execNodes{lv1};
                    % Then check if this node has a transferor.
                    if isfield(self.nodeTransferors, iterNode)
                        self.TransferData(self.nodeTransferors.(iterNode));
                    end
                end
                
                exec(t);
                if exist('ans','var')
                    self.hasOutput(lv1) = true;
                end
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%
            tOld     = 0;
            iterNode = ''; 
            while t <= tEnd
                
                % Check if it is time to update each node.
                % Note: a small tolerance of 1e-9 is used due to
                % accumulating rounding errors.
                % TODO: 1) Find a way to deal with the rounding errors, 
                %          as they will become even larger with longer 
                %          simulations.
                for lv1 = 1:length(nodeNextUpdateTimes)
                    if abs(t - nodeNextUpdateTimes(lv1)) < 1e-9 
                        % Update node state
                        exec = self.executables{lv1};                        
                        
                        % Run transferor
                        % First, check if any other nodes have been updated since
                        % the last time this node was updated.
                        if ~strcmp(iterNode,self.execNodes{lv1})
                            iterNode = self.execNodes{lv1};
                            % Then check if this node has a transferor.
                            if isfield(self.nodeTransferors, iterNode)
                                self.TransferData(self.nodeTransferors.(iterNode));
                            end
                        end
                        
                        % Check number of outputs of the executable. 
                        if self.hasOutput(lv1)
                            % Run executable
                            data_exec_k = exec(t);
                            % Append data
                            self.appendSimData(t,data_exec_k,lv1);
                        else
                            exec(t);
                        end

                        % Update next time to run update for this node.
                        nodeNextUpdateTimes(lv1) = nodeNextUpdateTimes(lv1) + 1/nodeFreq(lv1);
                    end
                end
                
                % Update waitbar at every 1% change
                if tOld ~= round((t - tStart)/(tEnd - tStart)*100)
                    waitbar((t - tStart)/(tEnd - tStart),self.waitbarHandle);
                    tOld = round((t - tStart)/(tEnd - tStart)*100);
                end
                
                % Soonest update time
                tNext = min(nodeNextUpdateTimes);
                
                % Go to soonest update time
                t = tNext;
            end
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Final bit of post-processing
            self.squeezeData()
            
            % Return the executables data
            data = self.execData;
            
            % Close waitbar
            close(self.waitbarHandle)
        end
        
        function showGraph(self)
            if isempty(self.nodeListeners)
                self.createListeners();
            end
            if isempty(self.nodeTransferors)
                self.createTransferors();
            end
            edgeTable = table([  ],[],'VariableNames',{'EndNodes' 'Label'});
            nodeNames = fieldnames(self.nodes);
            
            % Listeners
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
            
            % Transferors
            for lv1 = 1:numel(nodeNames)
                if isfield(self.nodeTransferors, nodeNames{lv1})
                    transferors = self.nodeTransferors.(nodeNames{lv1});
                    for lv2 = 1:length(transferors)  
                        T = transferors{lv2};
                        edgeTable = [edgeTable; {{T.eventNode,T.listeningNode},T.eventArg}];
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
        function appendSimData(self,t,data_k,execNumber)
            % Inserts the data of the specific time point into the 
            execName = self.names{execNumber};
            data_k.t = t;
            dataNames_k = fieldnames(data_k);
            
            if ~isfield(self.execData, execName) 
                % Preallocate data storage arrays
                % Total number of data points we will get.
                N = (self.timeSpan(end) - self.timeSpan(1))*self.frequencies(execNumber) + 1;
                for lv1 = 1:length(dataNames_k)
                    % Get size of single data value.
                    sz = size(data_k.(dataNames_k{lv1}));

                    % Create array, augmenting by a single dimension with N
                    % time points.
                    self.execData.(execName).(dataNames_k{lv1}) = zeros([sz, N]);
                end
            end
            
            % Data has already been preallocated
            indx = round((t - self.timeSpan(1))*self.frequencies(execNumber)) + 1;
            S.type = '()';
            for lv1 = 1:length(dataNames_k)
                n = ndims(data_k.(dataNames_k{lv1}));
                c = cell(1,n);
                c(:) = {':'};
                S.subs = [c,indx];
                
                % subsasgn is a special function to dynamically index into
                % a variable with unknown variable name.
                self.execData.(execName).(dataNames_k{lv1}) = subsasgn(self.execData.(execName).(dataNames_k{lv1}),S,data_k.(dataNames_k{lv1}));
            end
            
        end
        
        function squeezeData(self)
            % Squeeze to eliminate redundant dimensions.
            for lv1 = 1:length(self.executables)
                if isfield(self.execData,self.names{lv1})
                    data_exec = self.execData.(self.names{lv1});
                    dataNames = fieldnames(data_exec);
                    for lv2 = 1:numel(dataNames)
                        data_exec.(dataNames{lv2}) = squeeze(data_exec.(dataNames{lv2}));
                    end
                    self.execData.(self.names{lv1}) = data_exec;
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
        
        function createTransferors(self)
            % Run the createTransferors method of all classes.
            % TODO: 1) Update the interconnection graph to include
            %          transferors.
            self.nodeTransferors = struct();
            nodeNames = fieldnames(self.nodes);
            for lv1 = 1:length(nodeNames)
                nodeName = nodeNames{lv1};
                if ismethod(self.nodes.(nodeName),'createTransferors')
                    transferors = self.nodes.(nodeName).createTransferors();
                    self.nodeTransferors.(nodeName) = transferors; 
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
            self.execNodes   = {};
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
                self.execNodes   = [self.execNodes; {nodeName}];
                self.names = [self.names; [nodeName,'_',execName]];

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
                        self.execNodes   = [self.execNodes; {nodeName}];
                        self.names = [self.names; [nodeName,'_',execName]];
                    end
                end
            end
        end
        
        function TransferData(self,transferors)
            % A function to transfer data between nodes. 
            % Takes as input a cell of structs, where each object has the
            % following 4 properties:
            %   1) eventNode: Node to transfer data from.
            %   2) eventArg: Property containing the data in source node.
            %   3) listeningNode: Node to receive data.
            %   4) listeningArg: Property to receive data in sink node.
            % TODO: 1) Share timestamps.
            for lv1 = 1:1:length(transferors)
                iter = transferors{lv1};
                eventNode     = iter.eventNode;
                eventArg      = iter.eventArg;
                listeningNode = iter.listeningNode;
                listeningArg  = iter.listeningArg;
                self.nodes.(listeningNode).(listeningArg) = ...
                    self.nodes.(eventNode).(eventArg);
            end
        end
            
    end
end