import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hutomero_app/models/device.dart';
import '../models/mobile_alert.dart';
import '../models/sensor.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  /// Call the server login endpoint and capture the Set-Cookie header.
  /// Optionally provide a JSON body (e.g. credentials). The method stores
  /// the cookie for subsequent requests.
  Future<String?> login([Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl/login');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );

    final redirectLocation = resp.headers['location'] ?? '';
    if ((resp.statusCode != 200 || resp.statusCode != 302) && redirectLocation.contains('login')) {
      throw Exception('Login failed!');
    }

    final setCookie = resp.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      // Extract the first "name=value" segment before any ;
      return setCookie.split(';').first.trim();
    }
    return null;
  }

  Future<List<Sensor>> getSensors(String? cookie) async {
    final uri = Uri.parse('$baseUrl/api/latest-sensor-data?_t=${DateTime.now().toUtc().millisecondsSinceEpoch}');
    
    final headers = <String, String>{};
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }

    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load sensors!');
    }

    final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
    return jsonList
        .map((e) => Sensor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MobileAlert>> getAlerts(String? cookie) async {
    final uri = Uri.parse('$baseUrl/api/mobile/alerts');

    final headers = <String, String>{};
    if (cookie != null) {
      headers['Cookie'] = cookie;
    } else {
      throw Exception('Nincs érvényes munkamenet süti a riasztások lekéréséhez.');
    }

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('hibás lekérés!');
    }

    final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
    return jsonList
        .map((e) => MobileAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  Future<List<Device>> getAllDevices(String? cookie) async {
    final uri = Uri.parse('$baseUrl/api/mobile/devices-with-sensors');

    final headers = <String, String>{};
    if (cookie != null) {
      headers['Cookie'] = cookie;
    } else {
      throw Exception('Nincs érvényes munkamenet süti a riasztások lekéréséhez.');
    }

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('hibás lekérés!');
    }

    final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;

    final List<Device> devices = [];
    for (var i = 0; i < jsonList.length; i++) {
      final item = jsonList[i];
      try {
        if (item is Map<String, dynamic>) {
          devices.add(Device.fromJson(item));
        } else if (item is Map) {
          // loosely typed map
          devices.add(Device.fromJson(Map<String, dynamic>.from(item)));
        } else {
          throw Exception('Unexpected device JSON item at index $i: not an object');
        }
      } catch (e) {
        // include the offending item in the error to help debugging
        throw Exception('Failed to parse device at index $i: $e — data: ${item.toString()}');
      }
    }

    return devices;
  }
}
