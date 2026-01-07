import 'dart:convert';
import 'package:http/http.dart' as http;
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
      throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
    }

    final setCookie = resp.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      // Extract the first "name=value" segment before any ;
      return setCookie.split(';').first.trim();
    }
    return null;
  }

  Future<List<Sensor>> getSensors(String? cookie) async {
    final uri = Uri.parse('$baseUrl/api/latest-sensor-data');
    
    final headers = <String, String>{};
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }

    final resp = await http.get(uri, headers: headers);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load sensors: ${resp.statusCode} ${resp.body}');
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

    // Try parsing JSON first. The server may return a rendered HTML page
    // (302/HTML) containing the warnings; in that case we attempt to
    // extract a JSON array embedded in the HTML. Do not fail immediately
    // on non-200 status codes — parse the body instead.

    final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
    return jsonList
        .map((e) => MobileAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
