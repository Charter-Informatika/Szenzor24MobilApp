import 'package:flutter/material.dart';
import '../models/mobile_alert.dart';
import '../services/api_client.dart';

class AlertsPage extends StatefulWidget {
  final ApiClient api;
  final String sessionCookie;

  const AlertsPage({super.key, required this.api, required this.sessionCookie});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<MobileAlert>> futureAlerts;

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

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                futureAlerts = widget.api.getAlerts(widget.sessionCookie);
              });
            },
            child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final a = cards[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                a.sensorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              a.deviceName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a.value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildTypeChip(a.type),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _limitTextForType(a.type),
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _formatDateTime(a.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
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
