classdef DiscreteSimulation < handle
%DISCRETESIMULATION class for running multiple nodes in parallel, at
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
            maxFreq = 0;
            nodeFreq = zeros(length(nodeNames),1);
            for lv1 = 1:length(nodeNames)
                nodeFreq(lv1) = self.nodeFrequencies.(nodeNames{lv1});
                %if nodeFreq(lv1) > maxFreq
                    %maxFreq = nodeFreq(lv1);
                %end
            end

            % Start and end times
            tStart = self.timeSpan(1);
            tEnd = self.timeSpan(end);
            
            % Column matrix stores the next time that node should be
            % updated. Initlize all to tStart
            nodeNextUpdateTimes = tStart*ones(length(nodeFreq),1);
            t = tStart;
            self.data = struct();
            
            % %%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%
            while t <= tEnd
                
                data_k = struct();
                
                % Check if it is time to update each node.
                for lv1 = 1:length(nodeNextUpdateTimes)
                    if t == nodeNextUpdateTimes(lv1)
                        
                        % Update node state
                        node = self.nodes.(nodeNames{lv1});
                        if ismethod(node,'update')
                            data_node = node.update(t);
                            data_k = catstruct(data_k, data_node);
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
            dataNames_k = fieldnames(data_k);
            dataNames = fieldnames(self.data);
            
            % First, check to see if we are missing some fields in data_k
            % that are in self.data
            for lv1 = 1:length(dataNames)
                if ~isfield(data_k,dataNames{lv1})
                    % Field is missing in new data. Copy from previous
                    % datapoint.
                    % TODO - this is gross and complicated.
                    % The reason we need to do this is we do not know the
                    % dimension of the data until runtime (ex. could be a
                    % vector, or a DCM). But the time data is in the last
                    % dimension, and we need to concatenate in that
                    % dimension.
                    N = ndims(self.data.(dataNames{lv1}));
                    inds = repmat({1},1,N);
                    inds{N} = size(self.data.(dataNames{lv1}),N);
                    temp = self.data.(dataNames{lv1});   
                    N_point = ndims(temp(inds{:}));
                    self.data.(dataNames{lv1}) = cat(N_point+1,temp,temp(inds{:}));
                end
            end
            
            % Each field should contain only 1 value, so loop and keep
            % combining into a final data struct.
            for lv2 = 1:numel(dataNames_k)
                if isfield(self.data, dataNames_k{lv2})
                    % Check if there is a field already in self.data
                    
                    % If a field contains a matrix, append in the
                    % 3rd dimension. Generalized to N dimensions.
                    N = ndims(data_k.(dataNames_k{lv2}));
                    self.data.(dataNames_k{lv2}) = cat(N + 1, self.data.(dataNames_k{lv2}),...
                                                     data_k.(dataNames_k{lv2}));
                else
                    % Otherwise create the field.
                    self.data.(dataNames_k{lv2}) = [data_k.(dataNames_k{lv2})];
                end
            end
            
        end
        function createListeners(self)
            % Run the createListeners method of all classes.
            nodeNames = fieldnames(self.nodes);
            for lv1 = 1:length(nodeNames)
                if ismethod(self.nodes.(nodeNames{lv1}),'createListeners')
                    self.nodes.(nodeNames{lv1}).createListeners(self.nodes)
                end
            end
        end
    end
end        