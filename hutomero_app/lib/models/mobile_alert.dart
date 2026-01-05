class MobileAlert {
  final int id;
  final double value;
  final String type;      // 'hiba' / 'alatt' / 'felett'
  final String status;    // 'aktív' / 'megoldódott' / 'várakozik'
  final String? comment;
  final DateTime createdAt;
  final int sensorId;
  final String sensorName;
  final int deviceId;
  final String deviceName;
  final double? min;
  final double? max;

  MobileAlert({
    required this.id,
    required this.value,
    required this.type,
    required this.status,
    this.comment,
    required this.createdAt,
    required this.sensorId,
    required this.sensorName,
    required this.deviceId,
    required this.deviceName,
    this.min,
    this.max,
  });

  factory MobileAlert.fromJson(Map<String, dynamic> json) {
    return MobileAlert(
      id: json['id'] as int,
      value: (json['value'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sensorId: json['sensorId'] as int,
      sensorName: json['sensorName'] as String,
      deviceId: json['deviceId'] as int,
      deviceName: json['deviceName'] as String,
      min: json['min'] != null ? (json['min'] as num).toDouble() : null,
      max: json['max'] != null ? (json['max'] as num).toDouble() : null,
    );
  }
}
