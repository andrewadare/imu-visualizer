// Based on Euler.ino example

#include "NAxisMotion.h"

NAxisMotion imu;
unsigned long prevTime = 0;
const int streamPeriod = 20; // ms

void setup()
{
  Serial.begin(115200);
  I2C.begin();
  imu.initSensor(); // I2C Address can be changed here if needed
  imu.setOperationMode(OPERATION_MODE_NDOF);

  // Default update mode is AUTO.
  // MANUAL requires calling update functions prior to calling the read functions
  // Setting to MANUAL requires fewer reads to the sensor
  imu.setUpdateMode(MANUAL);
}

void loop()
{
  if ((millis() - prevTime) >= streamPeriod)
  {
    prevTime = millis();
    imu.updateEuler();        // Update the Euler data into the structure of the object
    imu.updateCalibStatus();  // Update the Calibration Status

    Serial.print("Time:");
    Serial.print(prevTime); // ms

    Serial.print(",H:");
    Serial.print(imu.readEulerHeading()); // deg

    Serial.print(",R:");
    Serial.print(imu.readEulerRoll()); // deg

    Serial.print(",P:");
    Serial.print(imu.readEulerPitch()); // deg

    // Calib status values range from 0 - 3
    Serial.print(",A:");
    Serial.print(imu.readAccelCalibStatus());

    Serial.print(",M:");
    Serial.print(imu.readMagCalibStatus());

    Serial.print(",G:");
    Serial.print(imu.readGyroCalibStatus());

    Serial.print(",S:");
    Serial.print(imu.readSystemCalibStatus());

    Serial.println();
  }
}