import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'sensors_page.dart';
import 'devices_page.dart';
// alerts_page is not used in the compact Home view

class HomePage extends StatefulWidget {
  final ApiClient api;
  final String sessionCookie;

  const HomePage({super.key, required this.api, required this.sessionCookie});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<String> _titles = ['Szenzorok', 'Eszközök'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      SensorsPage(api: widget.api, sessionCookie: widget.sessionCookie),
      DevicesPage(api: widget.api, sessionCookie: widget.sessionCookie),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 2,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Szenzorok'),
          BottomNavigationBarItem(icon: Icon(Icons.developer_board), label: 'Eszközök'),
        ],
      ),
    );
  }
}
