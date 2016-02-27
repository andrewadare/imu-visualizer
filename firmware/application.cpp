
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
  imu.setUpdateMode(MANUAL);
}

void loop()
{
  if ((millis() - prevTime) >= streamPeriod)
  {
    prevTime = millis();
    imu.updateQuat();
    imu.updateCalibStatus();

    Serial.print("Time:");
    Serial.print(prevTime); // ms

    // Quaternion values 
    Serial.print(",qw:");
    Serial.print(imu.readQuatW());
    Serial.print(",qx:");
    Serial.print(imu.readQuatX());
    Serial.print(",qy:");
    Serial.print(imu.readQuatY());
    Serial.print(",qz:");
    Serial.print(imu.readQuatZ());


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