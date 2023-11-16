classdef SerialTrigger
    
    properties
        serial_connection
        inter_trigger_interval
    end
    
    methods (Static = true, Access = private)
        function bits = triggerNumToBits(trigger_num)
            arguments 
                trigger_num int32 {mustBeNonnegative(trigger_num), mustBeLessThan(trigger_num,9)}
            end

            if trigger_num > 0
                bits = bitshift(1,trigger_num-1);
            else 
                bits = uint8(0);
            end
        end
    end
    
    methods
        % ctor
        function obj = SerialTrigger(port, baudrate, inter_trigger_interval)
            arguments
                port string
                baudrate double
                inter_trigger_interval double {mustBeNonnegative(inter_trigger_interval)}
            end
            
%             obj.serial_connection = serialport(port, baudrate);
%             write(obj.serial_connection, 0, 'uint8');
%             pause(obj.inter_trigger_interval);

            obj.serial_connection = serial(port, 'BaudRate', baudrate, 'TimeOut', 1);
            obj.inter_trigger_interval = inter_trigger_interval;
            fopen(obj.serial_connection);
        end

        function delete(obj)
            obj.disconnect();
        end

        function startUp(obj)
            fwrite(obj.serial_connection, 0,'sync');
            pause(obj.inter_trigger_interval);
        end

        function disconnect(obj)
            fclose(obj.serial_connection);
        end
        
        function trigger(obj, trigger_num)
            arguments
                obj SerialTrigger
                trigger_num int32 {mustBeNonnegative(trigger_num), mustBeLessThan(trigger_num,8)}
            end
            
%             write(obj.serial_connection, obj.triggerNumToBits(trigger_num), 'uint8');
%             pause(obj.inter_trigger_interval);
%             write(obj.serial_connection, 0, 'uint8');
%             pause(obj.inter_trigger_interval);

            fwrite(obj.serial_connection, obj.triggerNumToBits(trigger_num), 'sync');
            pause(obj.inter_trigger_interval);
            fwrite(obj.serial_connection, 0,'sync');
            pause(obj.inter_trigger_interval);
        end

        function start_trigger(obj, trigger_num)
            arguments
                obj SerialTrigger
                trigger_num int32 {mustBeNonnegative(trigger_num), mustBeLessThan(trigger_num,8)}
            end

%             write(obj.serial_connection, obj.triggerNumToBits(trigger_num), 'uint8');
%             pause(obj.inter_trigger_interval);
            fwrite(obj.serial_connection, obj.triggerNumToBits(trigger_num), 'sync');
            pause(obj.inter_trigger_interval);
        end

        function end_trigger(obj)
            arguments
                obj SerialTrigger
            end

%             write(obj.serial_connection, 0, 'uint8');
%             pause(obj.inter_trigger_interval);
            fwrite(obj.serial_connection, 0,'sync');
            pause(obj.inter_trigger_interval);
        end
        
        % probably useless
        function triggerBinary(obj, trigger)
            arguments
                obj SerialTrigger
                trigger unit8 {mustBeNonnegative(trigger), mustBeLessThan(trigger,255)}
            end
            
            write(obj.serial_connection, trigger, 'uint8');
            pause(obj.inter_trigger_interval);
            write(obj.serial_connection, 0, 'uint8');
            pause(obj.inter_trigger_interval);
        end
    end
end

% PROBABLY IRRELAVANT
% SerialPortObj = serial(serial_port, 'BaudRate', 115200, 'TimeOut', 1);
% fopen(SerialPortObj);
% % Set the port to zero state 0
% fwrite(SerialPortObj, 0,'sync');
% fclose(SerialPortObj);
% delete(SerialPortObj);
% clear SerialPortObj;

