classdef TestRig_SchwartzLab < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = TestRig_SchwartzLab()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            daq = HekaSimulationDaqController();
            obj.daqController = daq;
            
            amp1 = MultiClampDevice('AmpIn1', 1).bindStream(daq.getStream('ANALOG_OUT.0')).bindStream(daq.getStream('ANALOG_IN.0'));
            obj.addDevice(amp1);
            
            amp2 = MultiClampDevice('AmpIn2', 2).bindStream(daq.getStream('ANALOG_OUT.1')).bindStream(daq.getStream('ANALOG_IN.1'));
            obj.addDevice(amp2);
            
            amp3 = MultiClampDevice('AmpIn3', 2).bindStream(daq.getStream('ANALOG_OUT.2')).bindStream(daq.getStream('ANALOG_IN.2'));
            obj.addDevice(amp3);

            amp4 = MultiClampDevice('AmpIn4', 2).bindStream(daq.getStream('ANALOG_OUT.3')).bindStream(daq.getStream('ANALOG_IN.3'));
            obj.addDevice(amp4);
            
            trigger1 = UnitConvertingDevice('Trigger1', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('DIGITAL_OUT.1'));
            daq.getStream('DIGITAL_OUT.1').setBitPosition(trigger1, 0);
            obj.addDevice(trigger1);
            
            stage = io.github.stage_vss.devices.StageDevice('localhost');
            stage.addConfigurationSetting('micronsPerPixel', 1.6, 'isReadOnly', true);
            stage.addConfigurationSetting('projectorAngleOffset', 0, 'isReadOnly', true);

            obj.addDevice(stage);
            
%             lightCrafter = fi.helsinki.biosci.ala_laurila.devices.LightCrafterDevice();
%             lightCrafter.addConfigurationSetting('micronsPerPixel', 1.6, 'isReadOnly', true);
%             obj.addDevice(lightCrafter);
        end
    end
end

