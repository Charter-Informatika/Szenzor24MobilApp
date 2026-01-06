class Sensor {
  final int id;
  final String name;
  final SensorType type;

  final double? value;
  final DateTime? timestamp;

  Sensor ({
    required this.id,
    required this.name,
    required this.type,
    this.value,
    this.timestamp,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    String typeStr = (json['type'] as String).toLowerCase();
    SensorType sensorType = SensorType.fromString(typeStr);


    return Sensor(
      id: json['id'] as int,
      name: json['name'] as String,
      type: sensorType,
      value: json['value'] is num ? (json['value'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
    );
  }
}

enum SensorType {
  temperature,
  humidity,
  gyrometer,
  unknown;

  static SensorType fromString(String typeStr) {
    if (typeStr.contains('temperature')) {
      return SensorType.temperature;
    } else if (typeStr.contains('humidity')) {
      return SensorType.humidity;
    } else if (typeStr.contains('gyro')) {
      return SensorType.gyrometer;
    } else {
      return SensorType.unknown;
    }
  }
}