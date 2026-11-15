# ActiveSensor provides a way to collect data from sensors.
# In this first version, sensor are supposed to be read on regular interval
module ActiveSensor
  class EquipmentNotFound < StandardError
  end

  class MissingParameter < StandardError
  end
end
