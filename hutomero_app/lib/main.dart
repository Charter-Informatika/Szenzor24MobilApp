import 'package:flutter/material.dart';
import 'models/mobile_alert.dart';
import 'services/api_client.dart';

//add a dotenv/secret file later
const String baseUrl = 'baseUrl';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okoshűtő riasztások',
      theme: ThemeData.dark(),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final api = ApiClient(baseUrl: baseUrl);
    try {
      final cookie = await api.login({
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });

      if (cookie == null) {
        setState(() {
          _error = 'Sikertelen bejelentkezés (nincs süti).';
          _loading = false;
        });
        return;
      }

      // Navigate to alerts page, passing the api client and cookie
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => AlertsPage(api: api, sessionCookie: cookie),
      ));
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bejelentkezés')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _doLogin,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Bejelentkezés'),
            ),
          ],
        ),
      ),
    );
  }
}

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

          // 👉 Szenzoronként csak az első (legfrissebb) riasztás
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
                        // Felső sor: szenzor név + eszköz
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

                        // Érték + típus
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

                        // “határ” info – itt egyszerűen jelezzük, hogy ez most kívül van
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
