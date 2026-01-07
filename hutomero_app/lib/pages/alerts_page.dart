import 'package:flutter/material.dart';
import '../models/mobile_alert.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class AlertsPage extends StatefulWidget {
  final ApiClient api;
  final String sessionCookie;

  const AlertsPage({super.key, required this.api, required this.sessionCookie});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<MobileAlert>> futureAlerts;
  Map<int, MobileAlert>? _previousBySensor;

  @override
  void initState() {
    super.initState();
    futureAlerts = widget.api.getAlerts(widget.sessionCookie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riasztások'),
      ),
      body: FutureBuilder<List<MobileAlert>>(
        future: futureAlerts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Hiba: ${snapshot.error}'),
            );
          }

          final alerts = snapshot.data ?? [];

          // Szenzoronként csak az első (legfrissebb) riasztás
          final Map<int, MobileAlert> bySensor = {};
          for (final a in alerts) {
            bySensor.putIfAbsent(a.sensorId, () => a);
          }

          final cards = bySensor.values.toList();

          if (cards.isEmpty) {
            return const Center(child: Text('Nincs aktív riasztás.'));
          }

          // Detect changes compared to previous fetch and notify once per change.
          final List<MobileAlert> changed = [];
          if (_previousBySensor != null) {
            for (final entry in bySensor.entries) {
              final prev = _previousBySensor![entry.key];
              final cur = entry.value;
              final bool isChanged = prev == null || prev.status != cur.status || prev.type != cur.type || prev.value != cur.value;
              if (isChanged) changed.add(cur);
            }
          }

          if (changed.isNotEmpty) {
            Future.microtask(() async {
              final svc = NotificationService();
              for (final a in changed) {
                final title = a.sensorName.isNotEmpty ? '${a.sensorName} - ${a.deviceName}' : 'Szenzor #${a.sensorId} - ${a.deviceName}';
                final body = '${a.type} • ${a.value.toStringAsFixed(1)} • ${a.status}';
                try {
                  await svc.showWarningChanged(id: a.sensorId, title: title, body: body);
                } catch (_) {}
              }
            });
          }

          // update previous snapshot
          _previousBySensor = Map<int, MobileAlert>.from(bySensor);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                futureAlerts = widget.api.getAlerts(widget.sessionCookie);
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final a = cards[index];

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
                        backgroundColor: Colors.redAccent.withOpacity(0.12),
                        child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 18),
                      ),
                      title: Text(
                        a.sensorName.trim().isNotEmpty ? a.sensorName : (a.deviceName.trim().isNotEmpty ? a.deviceName : 'Ismeretlen szenzor'),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.titleMedium?.color),
                      ),
                      subtitle: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            '${a.deviceName.isNotEmpty ? a.deviceName + ' • ' : ''}${_formatDateTime(a.createdAt)}',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTypeChip(a.type),
                            _buildStatusChip(a.status),
                          ],
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 64,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(a.value.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ),
                    ),
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

Widget _buildTypeChip(String type) {
  Color color;
  String text;

  switch (type) {
    case 'alatt':
      color = Colors.blueAccent;
      text = 'Határ alatt';
      break;
    case 'felett':
      color = Colors.orangeAccent;
      text = 'Határ felett';
      break;
    case 'hiba':
    default:
      color = Colors.redAccent;
      text = 'Hiba';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.9), width: 0.9),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _buildStatusChip(String status) {
  final bool active = status == 'aktív';
  final Color color = active ? Colors.redAccent : Colors.greenAccent;
  final String text = active ? 'Aktív' : status;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.95), width: 0.9),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _limitTextForType(String type) {
  switch (type) {
    case 'alatt':
      return 'Túl alacsony érték';
    case 'felett':
      return 'Túl magas érték';
    case 'hiba':
      return 'Szenzor hiba';
    default:
      return 'Kívül a határértéken';
  }
}
