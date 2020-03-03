classdef RelativePositionSensor < handle
    properties (SetObservable)
        measurement  
    end
    properties 
        ID
        r_zw_a
        r_iw_a
        r_iz_a
        numAgents
    end
    methods
        function self = RelativePositionSensor(agentID)
            self.ID = agentID; % This sensor is on agent "ID"
            self.r_iz_a = zeros(3,100);
            self.r_iw_a = zeros(3,100);
            self.r_zw_a = zeros(3,1);
        end
        function createListeners(self,nodes)
            nodeNames = fieldnames(nodes);
            
            % Create listener for every agent in the simulation.
            self.numAgents = 0;
            for lv1 = 1:numel(fieldnames(nodes))
                if strcmp(nodeNames{lv1}, ['agent',num2str(lv1)]) && ...
                  ~strcmp(nodeNames{lv1}, ['agent',num2str(self.ID)])
                    addlistener(nodes.(nodeNames{lv1}),'position','PostSet',@self.cbRelPos)
                    self.numAgents = self.numAgents + 1;
                end
            end
            self.r_iz_a = zeros(3,self.numAgents);
            self.r_iw_a = zeros(3,self.numAgents);
            
            % Create listener for our own position
            addlistener(nodes.(['agent',num2str(self.ID)]),'position','PostSet',@self.cbPosition)
        end
        
        function cbPosition(self,src,evnt)
            self.r_zw_a = evnt.AffectedObject.position;
            
            % Refresh the relative positions
            self.r_iz_a = self.r_iw_a - self.r_zw_a;
        end
        
        function cbRelPos(self,src,evnt)
            self.r_iw_a = evnt.AffectedObject.position;
            
            % Refresh the relative positions
            self.r_iz_a = self.r_iw_a - self.r_zw_a;
        end
        
        function data = update(self,t)
            self.measurement = self.r_iz_a;
            data.y_uwb = self.measurement;
        end
        
    end
end
            