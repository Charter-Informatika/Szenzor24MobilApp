import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../models/mobile_alert.dart';
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
  Map<int, MobileAlert> _alertsBySensor = {};

  Future<List<Sensor>> _loadData() async {
    // Fetch sensors and alerts in parallel. Alerts are optional — failures are ignored.
    try {
      final results = await Future.wait([
        widget.api.getSensors(widget.sessionCookie),
        widget.api.getAlerts(widget.sessionCookie),
      ]);

      final sensors = results[0] as List<Sensor>;
      final alerts = results[1] as List<MobileAlert>;

      // Keep the most recent alert per sensor (assume list is ordered newest-first or use last)
      final Map<int, MobileAlert> bySensor = {};
      for (final a in alerts) {
        bySensor[a.sensorId] = a;
      }
      _alertsBySensor = bySensor;

      return sensors;
    } catch (e) {
      // If alerts fetching fails, still fetch sensors alone.
      try {
        final sensors = await widget.api.getSensors(widget.sessionCookie);
        _alertsBySensor = {};
        return sensors;
      } catch (err) {
        rethrow;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    futureSensors = _loadData();
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final s = sensors[index];
              final bool hasNoData = s.value == null;
              final bool hasAlert = _alertsBySensor.containsKey(s.id);
              final bool hasError = hasNoData || hasAlert;
              final valueText = hasNoData ? 'HIBA' : s.value!.toStringAsFixed(1);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _typeColor(s.type).withOpacity(0.12),
                    child: Icon(_typeIcon(s.type), color: _typeColor(s.type), size: 18),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name.trim().isNotEmpty
                              ? s.name
                              : (_alertsBySensor.containsKey(s.id) ? _alertsBySensor[s.id]!.deviceName : 'Ismeretlen szenzor'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      // status icons shown beside the numeric value in the trailing area
                    ],
                  ),
                  subtitle: Text(
                    hasNoData
                      ? 'Hiba: nincs adat'
                      : hasAlert
                        ? '${_alertsBySensor[s.id]!.deviceName} • ${_formatDateTime(s.timestamp ?? DateTime.now())} • Riasztás: ${_alertsBySensor[s.id]!.type}'
                        : _formatDateTime(s.timestamp ?? DateTime.now()),
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            valueText,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasError ? Colors.redAccent : Colors.lightGreenAccent),
                          ),
                          if (hasNoData)
                            const Padding(
                              padding: EdgeInsets.only(left: 6.0),
                              child: Icon(Icons.error_rounded, color: Colors.redAccent, size: 16),
                            ),
                          if (!hasNoData && hasAlert)
                            const Padding(
                              padding: EdgeInsets.only(left: 6.0),
                              child: Icon(Icons.warning_rounded, color: Colors.redAccent, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_typeLabel(s.type), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
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
      return 'Hőmérséklet';
    case SensorType.humidity:
      return 'Páratartalom';
    case SensorType.gyrometer:
      return 'Giro';
    case SensorType.unknown:
      return 'Ismeretlen';
  }
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

IconData _typeIcon(SensorType t) {
  switch (t) {
    case SensorType.temperature:
      return Icons.thermostat_rounded;
    case SensorType.humidity:
      return Icons.opacity_rounded;
    case SensorType.gyrometer:
      return Icons.rotate_right_rounded;
    case SensorType.unknown:
    default:
      return Icons.device_unknown_rounded;
  }
}

Color _typeColor(SensorType t) {
  switch (t) {
    case SensorType.temperature:
      return Colors.orangeAccent;
    case SensorType.humidity:
      return Colors.cyanAccent;
    case SensorType.gyrometer:
      return Colors.purpleAccent;
    case SensorType.unknown:
      return Colors.grey;
  }
}
