classdef MovingBar < sa_labs.protocols.StageProtocol

    properties
        preTime = 250                   % Bar leading duration (ms)
        tailTime = 250                  % Bar trailing duration (ms)
        intensity = 1.0                 % Bar light intensity (0-1)
        barLength = 600                 % Bar length size (um)
        barWidth = 200                  % Bar Width size (um)
        barSpeed = 1000                 % Bar speed (um / s)
        distance = 3000                 % Bar distance (um)
        angleOffset = 0                 % Angle set offset (deg)
        numberOfAngles = 12             % Number of angles to stimulate
        numberOfCycles = 3              % Number of times through the set
        singleEdgeMode = false          % Only display leading edge of bar, set length > 2 * distance
    end
    
    properties (Hidden)
        version = 6                     % v6: added angleOffset @sam
        angles                          % angles for epochs, range between [0 - 360]
        barAngle                        % Moving bar angle for the current epoch @see prepareEpoch 
        
        responsePlotMode = 'polar';
        responsePlotSplitParameter = 'barAngle';
    end
    
    properties (Dependent)
        stimTime                        % Bar duration (ms)
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
               
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            obj.angles = mod(round(0:360/obj.numberOfAngles:(360-.01)) + obj.angleOffset, 360);
        end
        
        function prepareEpoch(obj, epoch)
            
            index = mod(obj.numEpochsPrepared, obj.numberOfAngles);
            if index == 0
                obj.angles = obj.angles(randperm(obj.numberOfAngles));
            end
            
            obj.barAngle = obj.angles(index+1);
            epoch.addParameter('barAngle', obj.barAngle);

            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
        end        
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            bar = stage.builtin.stimuli.Rectangle();
            bar.color = obj.intensity;
            bar.opacity = 1;
            bar.orientation = obj.barAngle;
            bar.size = [obj.um2pix(obj.barLength), obj.um2pix(obj.barWidth)];
            p.addStimulus(bar);
            
            [~, pixelSpeed] = obj.um2pix(obj.barSpeed);
            [~, pixelDistance] = obj.um2pix(obj.distance);
            xStep = pixelSpeed * cosd(obj.barAngle);
            yStep = pixelSpeed * sind(obj.barAngle);

            if obj.singleEdgeMode
                stepBack = obj.um2pix(obj.barLength / 2); % move bar back half a length to time-center leading edge
            else
                stepBack = 0;
            end
            xStartPos = canvasSize(1)/2 - (pixelDistance / 2 + stepBack) * cosd(obj.barAngle);
            yStartPos = canvasSize(2)/2 - (pixelDistance / 2 + stepBack) * sind(obj.barAngle);
            
            function pos = movementController(state)
                pos = [NaN, NaN];
                t = state.time - obj.preTime * 1e-3;
                if t >= 0 && t < obj.stimTime * 1e-3
                    pos = [xStartPos + t * xStep, yStartPos + t * yStep];
                end
            end
            
            barMovement = stage.builtin.controllers.PropertyController(bar, 'position', @(state)movementController(state));
            p.addController(barMovement);
            
            
            % shared code for multi-pattern objects
            obj.setColorController(p, bar);
            
        end
                
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * obj.numberOfAngles;
        end        

        function stimTime = get.stimTime(obj)
            t = obj.distance / obj.barSpeed;
            stimTime = 1e3 * t;
        end
    end
    
end

