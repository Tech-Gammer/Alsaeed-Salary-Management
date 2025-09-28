import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class AuthService {
  // static const String baseUrl = "http://localhost:3000/api/auth";
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/auth";
    }
    return "http://localhost:3000/api/auth";
  }
  static Future<bool> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
    } else {
      final data = jsonDecode(response.body);
      // Throw the backend message (e.g. "User not found", "Invalid credentials")
      throw Exception(data["message"] ?? "Login failed");
    }
  }


}
