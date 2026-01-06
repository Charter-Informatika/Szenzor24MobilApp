import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../services/api_client.dart';

class SensorsPage extends StatefulWidget {
  final ApiClient api;
  final String sessionCookie;

  const SensorsPage({super.key, required this.api, required this.sessionCookie});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  late Future<List<Sensor>> futureSensors;

  @override
  void initState() {
    super.initState();
    futureSensors = widget.api.getSensors(widget.sessionCookie);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sensor>>(
      future: futureSensors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hiba: ${snapshot.error}'));
        }

        final sensors = snapshot.data ?? [];
        if (sensors.isEmpty) {
          return const Center(child: Text('Nincsenek szenzorok.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureSensors = widget.api.getSensors(widget.sessionCookie);
            });
          },
          child: ListView.builder(
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final s = sensors[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _typeLabel(s.type),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.value != null ? s.value!.toStringAsFixed(1) : '-',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                          Text(
                            s.timestamp != null ? _formatDateTime(s.timestamp!) : '-',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _typeLabel(SensorType t) {
  switch (t) {
    case SensorType.temperature:
      return 'Hőm.';
    case SensorType.humidity:
      return 'Pár.';
    case SensorType.gyrometer:
      return 'Giro';
    case SensorType.unknown:
    default:
      return 'Ismeretlen';
  }
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
