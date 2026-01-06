import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'alerts_page.dart';
import 'sensors_page.dart';

class HomePage extends StatelessWidget {
  final ApiClient api;
  final String sessionCookie;

  const HomePage({super.key, required this.api, required this.sessionCookie});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Okoshűtő'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Szenzorok'),
              Tab(text: 'Riasztások'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SensorsPage(api: api, sessionCookie: sessionCookie),
            AlertsPage(api: api, sessionCookie: sessionCookie),
          ],
        ),
      ),
    );
  }
}
