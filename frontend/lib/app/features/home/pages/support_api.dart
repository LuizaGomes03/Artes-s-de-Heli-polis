import 'dart:convert';
import 'package:http/http.dart' as http;

class SupportChatMessage {
  final String role;
  final String content;

  const SupportChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class SupportApi {
  final String baseUrl;
  const SupportApi({required this.baseUrl});

  Future<String> sendMessage({
    required String language,
    required List<SupportChatMessage> messages,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'language': language,
            'messages': messages.map((m) => m.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 45));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Chat API error');
    }

    final reply = data['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw Exception('Empty assistant response');
    }

    return reply.trim();
  }
}
