#include "NAxisMotion.h"

NAxisMotion imu;
unsigned long prevTime = 0;
const int streamPeriod = 50; // ms

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

    String s = String("{\"time\":") + prevTime
               + String(", \"type\":") + String("\"angles\"")
               + String(", \"qw\":") + imu.readQuatW()
               + String(", \"qx\":") + imu.readQuatX()
               + String(", \"qy\":") + imu.readQuatY()
               + String(", \"qz\":") + imu.readQuatZ()
               + String(", \"A\":") + imu.readAccelCalibStatus()
               + String(", \"M\":") + imu.readMagCalibStatus()
               + String(", \"G\":") + imu.readGyroCalibStatus()
               + String(", \"S\":") + imu.readSystemCalibStatus()
               + "}";
    Serial.println(s);
  }
}
