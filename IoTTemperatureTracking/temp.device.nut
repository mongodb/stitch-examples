#require "HTS221.device.lib.nut:2.0.1"
#require "LPS22HB.class.nut:1.0.0"

// Define constants
const sleepTime = 120;

// Declare Global Variables
tempSensor <- null;
pressureSensor <- null;
led <- null

// Define functions
function takeReading(){
    local conditions = {};
    local reading = tempSensor.read();
    conditions.temp <- reading.temperature;
    conditions.humid <- reading.humidity;
    reading = pressureSensor.read();
    conditions.press <- reading.pressure;

    // Send 'conditions' to the agent
    agent.send("reading.sent", conditions);

    // Set the imp to sleep when idle, ie. program complete
    imp.onidle(function() {
        server.sleepfor(sleepTime);
    });
}

// Start of program

// Configure I2C bus for sensors
local i2c = hardware.i2c89;
i2c.configure(CLOCK_SPEED_400_KHZ);

tempSensor = HTS221(i2c);
tempSensor.setMode(HTS221_MODE.ONE_SHOT);

pressureSensor = LPS22HB(i2c);
pressureSensor.softReset();

// Take a reading
takeReading();
