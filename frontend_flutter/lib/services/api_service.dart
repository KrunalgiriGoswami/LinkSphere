import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  final String? jwtToken;

  ApiService({this.jwtToken});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      await prefs.setString('email', email);
      await prefs.setString(
        'username',
        data['username'] ?? email.split('@')[0],
      );
      return {'success': true, 'token': data['token']};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Login failed',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String username,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      await prefs.setString('username', username);
      return {'success': true};
    } else {
      return {
        'success': false,
        'message':
            jsonDecode(response.body)['message'] ?? 'Registration failed',
      };
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var profile = jsonDecode(response.body);
      // Decode education, experience, location, and contactInfo from JSON strings to lists/maps
      profile['education'] =
          profile['education'] != null && profile['education'].isNotEmpty
              ? jsonDecode(profile['education'])
              : [];
      profile['experience'] =
          profile['experience'] != null && profile['experience'].isNotEmpty
              ? jsonDecode(profile['experience'])
              : [];
      profile['location'] =
          profile['location'] != null && profile['location'].isNotEmpty
              ? jsonDecode(profile['location'])
              : {'city': '', 'postalCode': '', 'state': '', 'country': ''};
      profile['contactInfo'] =
          profile['contactInfo'] != null && profile['contactInfo'].isNotEmpty
              ? jsonDecode(profile['contactInfo'])
              : {'email': '', 'contactNo': '', 'website': ''};
      return profile;
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<void> createProfile(
    String headline,
    String about,
    String skills,
    List<dynamic> education,
    List<dynamic> experience,
    Map<String, dynamic> location,
    Map<String, dynamic> contactInfo,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'headline': headline,
        'about': about,
        'skills': skills,
        'education': jsonEncode(education),
        'experience': jsonEncode(experience),
        'location': jsonEncode(location),
        'contactInfo': jsonEncode(contactInfo),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create profile: ${response.body}');
    }
  }

  Future<void> updateProfile(
    String headline,
    String about,
    String skills,
    List<dynamic> education,
    List<dynamic> experience,
    Map<String, dynamic> location,
    Map<String, dynamic> contactInfo,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'headline': headline,
        'about': about,
        'skills': skills,
        'education': jsonEncode(education),
        'experience': jsonEncode(experience),
        'location': jsonEncode(location),
        'contactInfo': jsonEncode(contactInfo),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
