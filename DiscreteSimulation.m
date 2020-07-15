classdef DiscreteSimulation < handle
    % DISCRETESIMULATION class for running multiple nodes in parallel, at
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
        timeSpan
        executables
        subscribers
        frequencies
        names
        execData
    end
    properties (Access = private)
        waitbarHandle
        numOutput
        execNodes
        timestamps
    end
    
    methods
        function self = DiscreteSimulation()
            % Constructor
            self.timeSpan = [0 10];
        end
        
        function addNode(self, node, nodeName)
            % Add node to list of nodes.
            % Inputs:
            % --------
            % node: Object
            %       An instantiation of a a specific node object.
            %
            % nodeName: string
            %       specific name to call that node, can be different
            %       from the class name.
            
            self.nodes.(nodeName) = node;
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
            
            % Create subscribers
            self.createSubscribers()
            
            % Create executables (all asynchronous functions)
            self.createExecutables()
            
            % Get node frequencies
            nodeFreq = self.frequencies;
            
            % Start and end times
            tStart = self.timeSpan(1);
            tEnd = self.timeSpan(end);
            
            % Column matrix stores the next time that executable should be
            % updated. Initialize all to tStart
            nodeNextUpdateTimes = tStart*ones(length(nodeFreq),1);
            t = tStart;
            
            
            % Run all executables once to initialize everything.
            % Check and record how many variables does the function output.
            self.numOutput = zeros(length(self.executables),1);
            for lv1 = 1:length(self.executables)
                exec = self.executables{lv1};
                try
                    [~,~] = exec(t);
                    self.numOutput(lv1) = 2;
                catch
                    try
                        [~] = exec(t);
                        self.numOutput(lv1) = 1;
                    catch
                        exec(t);
                        self.numOutput(lv1) = 0;
                    end
                end
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%
            tOld = 0;
            while t <= tEnd
                
                % Check if it is time to update each node.
                % Note: a small tolerance of 1e-9 is used due to
                % accumulating rounding errors.
                % TODO: 1) Find a way to deal with the rounding errors,
                %          as they will become even larger with longer
                %          simulations.
                for lv1 = 1:length(nodeNextUpdateTimes)
                    if abs(t - nodeNextUpdateTimes(lv1)) < 1e-6
                        
                        % Extract executable function handle
                        exec = self.executables{lv1};
                        
                        % Check number of outputs of the executable.
                        % If 2 outputs, then post-processing data and
                        % publishers are to be addressed.
                        % If 1 output, then check which one is it.
                        if self.numOutput(lv1) == 2
                            % Run executable
                            [data_exec_k, publishers] = exec(t);
                            
                            % Append data
                            self.appendSimData(t,data_exec_k, lv1);
                            
                            % Transfer data
                            self.sendToSubscribers(publishers,t);
                            
                        elseif self.numOutput(lv1) == 1
                            outputIter = exec(t);
                            % check if output is postprocessing data or a
                            % publisher
                            if isfield(outputIter,'topic') && isfield(outputIter,'value')
                                % Transfer data
                                self.sendToSubscribers(outputIter,t)
                            else                  % then, outputIter = data_exec_k.
                                % Append data
                                self.appendSimData(t,outputIter,lv1);
                            end
                        elseif self.numOutput(lv1) == 0
                            exec(t);
                        end
                        
                        % Update next time to run update for this node.
                        % TODO - this still needs improvement.
                        nodeNextUpdateTimes(lv1) = round(nodeNextUpdateTimes(lv1) + 1/nodeFreq(lv1),10);
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
            % TODO: this doesnt work right now
            
            % As it stands we would need to run each exec once and go
            % collect all the publishers.
            
            if isempty(self.nodeTransferors)
                self.createTransferors();
            end
            edgeTable = table([  ],[],'VariableNames',{'EndNodes' 'Label'});
            nodeNames = fieldnames(self.nodes);
            
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
            
            % Initialize executable entry in data struct if it does not
            % exist.
            if ~isfield(self.execData, execName)
                self.execData.(execName) = struct();
            end
            
            % Total number of data points we will get.
            N = (self.timeSpan(end) - self.timeSpan(1))*self.frequencies(execNumber) + 1;
            for lv1 = 1:length(dataNames_k)
                if ~isfield(self.execData.(execName),dataNames_k{lv1})
                    % Initialize and preallocate data storage arrays if a
                    % particular data does not yet exist in exec data
                    % struct.
                    
                    % Get size of single data value.
                    sz = size(data_k.(dataNames_k{lv1}));
                    
                    % Create array, augmenting by a single dimension with N
                    % time points.
                    self.execData.(execName).(dataNames_k{lv1}) = zeros([sz, N]);
                    
                end
                
                % Data has already been preallocated
                indx = round((t - self.timeSpan(1))*self.frequencies(execNumber)) + 1;
                S.type = '()';
                
                n = ndims(data_k.(dataNames_k{lv1}));
                c = cell(1,n);
                c(:) = {':'};
                S.subs = [c,indx];
                
                % subsasgn is a special function to dynamically index into
                % a variable with unknown variable name.
                if ~isempty(data_k.(dataNames_k{lv1}))
                    self.execData.(execName).(dataNames_k{lv1}) = subsasgn(self.execData.(execName).(dataNames_k{lv1}),S,data_k.(dataNames_k{lv1}));
                end
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
        
        function createSubscribers(self)
            % Run the createSubcribers method of all classes.
            self.subscribers = struct();
            nodeNames = fieldnames(self.nodes);
            counter = 1;
            
            % Go through each node and run createSubscribers()
            for lv1 = 1:length(nodeNames)
                nodeName = nodeNames{lv1};
                if ismethod(self.nodes.(nodeName),'createSubscribers')
                    nodeSubs = self.nodes.(nodeName).createSubscribers();
                    
                    % Loop through all subscribers returned.
                    for lv2 = 1:length(nodeSubs)
                        sub = nodeSubs(lv2);
                        self.subscribers(counter).topic = sub.topic;
                        self.subscribers(counter).node = nodeName;
                        
                        % Optional parameter - destination variable.
                        if isfield(sub,'destination') 
                            if ~isempty(sub.destination)
                                self.subscribers(counter).destination = sub.destination;
                            else
                                self.subscribers(counter).destination = false;
                            end
                        else
                            self.subscribers(counter).destination = false;
                        end
                        
                        % Optional parameter - timestamps.
                        if isfield(sub,'timestamps') 
                            if ~isempty(sub.timestamps)
                                self.subscribers(counter).timestamps = sub.timestamps;
                            else
                                self.subscribers(counter).timestamps = false;
                            end
                        else
                            self.subscribers(counter).timestamps = false;
                        end
                        
                        % Optional parameter - callback.
                        if isfield(sub,'callback') 
                            if ~isempty(sub.callback)
                                self.subscribers(counter).callback = sub.callback;
                            else
                                self.subscribers(counter).callback = false;
                            end
                        else
                            self.subscribers(counter).callback = false;
                        end
         
                        counter = counter + 1;
                    end
                    
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
                nodeName = nodeNames{lv1};
                
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
        
        function sendToSubscribers(self,publishers,t)
            
            % Topics of all subscribers.
            topicList = {self.subscribers(:).topic};
            for lv1 = 1:length(publishers)
                topic = publishers(lv1).topic;
                
                % If publishers provided custom timestamp, send it.
                % Otherwise just use the simulator clock.
                if isfield(publishers(lv1),'timestamp')
                    timestamp = publishers(lv1).timestamp;
                else
                    timestamp = t;
                end
                
                % Get only the subscribers that are subscribed to this
                % topic.
                isSubscribed = ismember(topicList,topic);
                subs = self.subscribers(isSubscribed);
                
                % Send the data to each subscriber
                for lv2 = 1:length(subs)
                    if isa(subs(lv2).destination,'char')
                        if subs(lv2).timestamps
                            self.nodes.(subs(lv2).node).(subs(lv2).destination) = struct();
                            self.nodes.(subs(lv2).node).(subs(lv2).destination).value = ...
                                publishers(lv1).value;
                            self.nodes.(subs(lv2).node).(subs(lv2).destination).t = timestamp;
                        else
                            self.nodes.(subs(lv2).node).(subs(lv2).destination) = ...
                                publishers(lv1).value;
                        end
                    end
                    
                    % Run callback if it exists
                    if isa(subs(lv2).callback,'function_handle')
                        cb = subs(lv2).callback;
                        cb(timestamp,publishers(lv1).value);
                    end
                end
            end
        end
    end
end