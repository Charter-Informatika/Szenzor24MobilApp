import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mobile_alert.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<List<MobileAlert>> getAlerts(int userId) async {
    final uri = Uri.parse('$baseUrl/api/mobile/alerts?userId=$userId');

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Hiba a riasztások lekérésekor: ${resp.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;

    return jsonList
        .map((e) => MobileAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
