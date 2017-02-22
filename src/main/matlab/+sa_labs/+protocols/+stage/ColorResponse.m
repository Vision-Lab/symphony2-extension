classdef ColorResponse < sa_labs.protocols.StageProtocol
    
    properties
        preTime = 250                  % Spot leading duration (ms)
        stimTime = 1000                  % Spot duration (ms)
        tailTime = 1000                 % Spot trailing duration (ms)
        
        baseColor = [0.3, 0.3];
        contrast = 0.4;  % baseline
        spotDiameter = 200              % Spot diameter (um)
        numberOfCycles = 3               % Number of cycles through all contrasts
        enableSurround = false;
        surroundDiameter = 1000;
        
        colorChangeMode = 'ramp'
        numRampSteps = 8;
    end
    
    properties (Hidden)
        spotContrasts
        currentColors
    
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'sortColors';
        
        colorChangeModeType = symphonyui.core.PropertyType('char', 'row', {'swap','ramp'});
        
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    properties (Dependent)
        intensity
    end
    
    
    methods
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            if obj.numberOfPatterns == 1
                error('Must have > 1 pattern enabled to use color stim');
            end
            
            stepUp = 1 + obj.contrast;
            stepDown = 1 - obj.contrast;
            switch obj.colorChangeMode
                case 'swap'
                    obj.spotContrasts = [[stepUp,1];
                                      [1,stepUp];
                                      [stepUp,stepUp];
                                      [stepDown,1];
                                      [1,stepDown];
                                      [stepDown,stepDown];
                                      [stepUp,stepDown];
                                      [stepDown,stepUp]];
                case 'ramp'
                    rampSteps = linspace(.1, 3, obj.numRampSteps);
                    obj.spotContrasts = [[stepUp,.1];
                                      [stepUp,.2];
                                      [stepUp,.4];
                                      [stepUp,.6];
                                      [stepUp,1];
                                      [stepUp,1.3];
                                      [stepUp,1.6];
                                      [stepUp,2];
                                      [stepUp,3]];
            end
            
        end

        function prepareEpoch(obj, epoch)

            index = mod(obj.numEpochsPrepared, size(obj.spotContrasts, 1)) + 1;
            obj.currentColors = obj.baseColor .* obj.spotContrasts(index, :);

            epoch.addParameter('intensity1', obj.currentColors(1));
            epoch.addParameter('intensity2', obj.currentColors(2));
            epoch.addParameter('sortColors', sum([100,1] .* round(obj.currentColors*100))); % for plot display
            
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
        end
        
        
        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            function c = surroundColor(state, backgroundColor)
                c = backgroundColor(state.pattern + 1);
            end
            
            if obj.enableSurround
                surround = stage.builtin.stimuli.Ellipse();
                surround.color = 1;
                surround.opacity = 1;
                surround.radiusX = obj.um2pix(obj.surroundDiameter/2);
                surround.radiusY = surround.radiusX;
                surround.position = canvasSize / 2;
                p.addStimulus(surround);
                surroundColorController = stage.builtin.controllers.PropertyController(surround, 'color',...
                    @(s) surroundColor(s, obj.baseColor));
                p.addController(surroundColorController);
            end
            
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.color = 1;
            spot.opacity = 1;
            spot.radiusX = obj.um2pix(obj.spotDiameter/2);
            spot.radiusY = spot.radiusX;
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            function c = spotColor(state, onColor, backgroundColor)
                if state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3
                    c = onColor(state.pattern + 1);
                else
                    c = backgroundColor(state.pattern + 1);
                end
            end
                    
            spotColorController = stage.builtin.controllers.PropertyController(spot, 'color',...
                @(s) spotColor(s, obj.currentColors, obj.baseColor));
            p.addController(spotColorController);
            
        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = size(obj.spotContrasts, 1) * obj.numberOfCycles;
        end
        
        function intensity = get.intensity(obj)
            intensity = obj.baseColor(1);
        end
   
        
    end
    
end

