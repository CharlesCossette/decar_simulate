classdef DiscreteSimulation < handle
    % Discrete simulation class for running multiple nodes in parallel, at
    % difference frequencies. When you run a simulation with this class, it
    % basically does two things:
    %
    % 1) Checks to see what node needs to be updated next, and then
    %    updates that node by running node.update() function.
    % 2) Calls the user-supplied masterFunction() before any node gets
    %    updated.
    %
    % This continuously occurs, advancing the simulator time to the next
    % node update, until we reach the user provided end time.
    
    properties
        masterFunction
        nodes
        nodeFrequencies
        nodeNumStates
        timeSpan
    end
    properties (Access = private)
        waitbarHandle
        data
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
        end

        function dataOut = run(self)
            % RUN SIMULATION 
            % This function takes care of looping through the time span and
            % updating the nodes at each of their respective frequencies.
            
            % Some error checking
            if isempty(self.masterFunction)
                error('You must supply a master function')
            end
            
            % Create waitbar
            self.waitbarHandle = waitbar(0,'Simulation In Progress');
            
            % First, determine max frequency (brute force search)
            % Also store in a matrix instead of struct.
            nodeNames = fieldnames(self.nodes);
            maxFreq = 0;
            nodeFreq = zeros(length(nodeNames),1);
            for lv1 = 1:length(nodeNames)
                nodeFreq(lv1) = self.nodeFrequencies.(nodeNames{lv1});
                if nodeFreq(lv1) > maxFreq
                    maxFreq = nodeFreq(lv1);
                end
            end

            % Start and end times
            tStart = self.timeSpan(1);
            tEnd = self.timeSpan(end);
            
            % Column matrix stores the next time that node should be
            % updated. Initlize all to tStart
            nodeNextUpdateTimes = tStart*ones(length(nodeFreq),1);
            t = tStart;
            self.data = [];
            
            % %%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%
            while t <= tEnd
                % Call master
                data_k = self.masterFunction(t,self.nodes);
                
                % Check if it is time to update each node.
                for lv1 = 1:length(nodeNextUpdateTimes)
                    if t == nodeNextUpdateTimes(lv1)
                        
                        % Update node state
                        if ismethod(self.nodes.(nodeNames{lv1}),'update')
                            self.nodes.(nodeNames{lv1}).update(t);
                        end
                        
                        % Update next time to run update for this node.
                        nodeNextUpdateTimes(lv1) = nodeNextUpdateTimes(lv1) + 1/nodeFreq(lv1);
                    end
                end

                % Append data 
                self.appendSimData(t , data_k);
               
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
            dataNames = fieldnames(self.data);
            for lv1 = 1:numel(dataNames)
                self.data.(dataNames{lv1}) = squeeze(self.data.(dataNames{lv1}));
            end
            dataOut = self.data;
            
            % Close waitbar
            close(self.waitbarHandle)
        end 
        
    end
    
    methods (Access = private)
        function appendSimData(self,t,data_k)
            % Get all the field names from the sol_data struct.
            % TODO - inefficient, memory not preallocated.
            data_k.t = t;            
            dataNames = fieldnames(data_k);
            
            % Each field should contain only 1 value, so loop and keep
            % combining into a final data struct.
            for lv2 = 1:numel(dataNames)
                if isfield(self.data, dataNames{lv2})
                    % If a field contains a matrix, append in the
                    % 3rd dimension. Generalized to N dimensions.
                    N = ndims(data_k.(dataNames{lv2}));
                    self.data.(dataNames{lv2}) = cat(N+1, self.data.(dataNames{lv2}),...
                                                     data_k.(dataNames{lv2}));
                else
                    self.data.(dataNames{lv2}) = [data_k.(dataNames{lv2})];
                end
            end
            
        end
    end
end        