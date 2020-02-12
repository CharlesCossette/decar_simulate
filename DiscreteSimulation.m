classdef DiscreteSimulation < handle
    properties
        masterFunction
        nodes
        nodeFrequencies
        nodeNumStates
        timeSpan
    end
    
    methods
        function self = DiscreteSimulation()
            % Constructor
            self.timeSpan = linspace(0,10,100);
        end
        
        function addNode(self, node, nodeName, nodeFreq)
            % Add node to list of nodes
            self.nodes.(nodeName) = node;
            self.nodeFrequencies.(nodeName) = nodeFreq;
        end
        
        function getInitialConditions(self)
        end

        function run(self)
        end
        
    end
end
        