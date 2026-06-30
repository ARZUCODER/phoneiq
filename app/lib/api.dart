import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

const String apiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

class ApiClient {
  Future<ChatMessage> chat(String message, List<ChatMessage> history) async {
    final uri = Uri.parse('$apiBase/chat');
    final body = jsonEncode({
      'message': message,
      'history': history
          .map((m) => {'role': m.role, 'text': m.text})
          .toList(),
    });
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception('server ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final phones = (data['phones'] as List? ?? const [])
        .map((e) => Phone.fromJson(e as Map<String, dynamic>))
        .toList();
    final used = (data['used'] as List? ?? const [])
        .map((e) => UsedListing.fromJson(e as Map<String, dynamic>))
        .toList();
    return ChatMessage(
      role: 'assistant',
      text: data['reply'] ?? '',
      phones: phones,
      used: used,
    );
  }
}
