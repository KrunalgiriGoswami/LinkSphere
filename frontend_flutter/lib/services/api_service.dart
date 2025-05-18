import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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

  Future<String> uploadMedia(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts/upload'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['url'];
      } else {
        throw Exception('Failed to upload media: $responseBody');
      }
    } catch (e) {
      print('Error in uploadMedia: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> createPost(String description, String mediaUrls,
      String mediaTypes, String? profilePicture, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'description': description,
          'mediaUrls': mediaUrls,
          'mediaTypes': mediaTypes,
          'profilePicture': profilePicture,
          'username': username,
        }),
      );

      if (response.statusCode != 200) {
        print('Server response: ${response.body}');
        throw Exception('Failed to create post: ${response.body}');
      }
    } catch (e) {
      print('Error in createPost: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load posts: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/posts/search?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to search posts: ${response.body}');
    }
  }

  Future<void> likePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post: ${response.body}');
    }
  }

  Future<void> savePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/save'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save post: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getPostComments(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  Future<void> addComment(int postId, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  // Add these methods to your existing ApiService class

  Future<bool> checkIfLiked(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/liked'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      // If the endpoint doesn't exist, we'll assume the post is not liked
      return false;
    }
  }

  Future<void> unlikePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unlike post: ${response.body}');
    }
  }

  Future<void> deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<void> updatePost(int postId, String description, String mediaUrls,
      String mediaTypes) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'description': description,
        'mediaUrls': mediaUrls,
        'mediaTypes': mediaTypes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPostById(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get post: ${response.body}');
    }
  }

  Future<int> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        throw Exception('Failed to get current user ID: ${response.body}');
      }
    } catch (e) {
      // If the endpoint doesn't exist, we'll try to extract user ID from another source
      // This is a fallback mechanism
      return -1; // Return a default value indicating we couldn't get the ID
    }
  }
}
