import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiService {
  static const String apiUrl =
      'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json';

  Future<Map<String, dynamic>> fetchConfig() async {
  try {
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 10)); // Set timeout duration
        debugPrint('API Response: ${response.body}'); // Log the response body
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch config');
    }
  } catch (e) {
    rethrow; // This will allow errors like timeout to be handled properly in fetchConfig()
  }
}

}
