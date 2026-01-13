import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/sensor.dart';
import '../services/api_client.dart';

class DevicesPage extends StatefulWidget {
  final ApiClient api;
  final String sessionCookie;

  const DevicesPage({super.key, required this.api, required this.sessionCookie});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late Future<List<Device>> futureDevices;

  @override
  void initState() {
    super.initState();
    futureDevices = widget.api.getAllDevices(widget.sessionCookie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Device>>(
        future: futureDevices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}'));
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return const Center(child: Text('Nincsenek regisztrált eszközök.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                futureDevices = widget.api.getAllDevices(widget.sessionCookie);
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(child: Text(d.name.isNotEmpty ? d.name[0].toUpperCase() : '?')),
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.type ?? ''}${d.location != null && d.location!.isNotEmpty ? ' • ${d.location}' : ''}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tag, size: 16),
                                const SizedBox(width: 6),
                                Text(d.serial ?? 'Serial: -'),
                                const Spacer(),
                                Text(d.lastOnline != null ? _formatDateTime(d.lastOnline!) : 'Offline', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Szenzorok (${d.sensors.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: d.sensors.map((s) => _buildSensorChip(s)).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Widget _buildSensorChip(Sensor s) {
  final Color color;
  switch (s.type) {
    case SensorType.temperature:
      color = Colors.orangeAccent;
      break;
    case SensorType.humidity:
      color = Colors.blueAccent;
      break;
    case SensorType.gyrometer:
      color = Colors.purpleAccent;
      break;
    default:
      color = Colors.grey;
  }

  final valueText = s.value != null ? s.value!.toStringAsFixed(1) : '-';
  final timeText = s.timestamp != null ? _formatDateTime(s.timestamp!) : '';

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.9), width: 0.8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.name, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Row(children: [Text('$valueText', style: TextStyle(color: color, fontSize: 12)), const SizedBox(width: 8), Text(timeText, style: TextStyle(color: Colors.black54, fontSize: 11))]),
      ],
    ),
  );
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
