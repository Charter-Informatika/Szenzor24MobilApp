import 'sensor.dart'; 

class Device {
  final int id;
  final String name;
  final String? type;
  final String? location;
  final String? serial;
  final DateTime? lastOnline;
  final bool offlineEmail;
  final List<Sensor> sensors; // A beágyazott szenzor lista

  Device({
    required this.id,
    required this.name,
    this.type,
    this.location,
    this.serial,
    this.lastOnline,
    required this.offlineEmail,
    required this.sensors,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Névtelen eszköz',
      type: json['type'] as String?,
      location: json['location'] as String?,
      serial: json['serial'] as String?,
      // Dátum konvertálás biztonságosan
      lastOnline: json['last_online'] != null
          ? DateTime.tryParse(json['last_online'].toString())
          : null,
      offlineEmail: json['offlineEmail'] == true, // null check miatt safe
      // Szenzorok listájának mapelése
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((e) => Sensor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}