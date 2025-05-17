import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  String? _username;
  String? _email;
  File? _profileImage;
  String? _profileImagePath;
  File? _bannerImage;
  String? _bannerImagePath;
  Map<String, dynamic>? _profile;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  String? get username => _username;
  String? get email => _email;
  File? get profileImage => _profileImage;
  String? get profileImagePath => _profileImagePath;
  File? get bannerImage => _bannerImage;
  String? get bannerImagePath => _bannerImagePath;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'User';
    _email = prefs.getString('email') ?? 'email@example.com';
    _profileImagePath = prefs.getString('profile_image_path');
    _bannerImagePath = prefs.getString('banner_image_path');
    if (_profileImagePath != null) {
      _profileImage = File(_profileImagePath!);
    }
    if (_bannerImagePath != null) {
      _bannerImage = File(_bannerImagePath!);
    }

    // Load education, experience, location, and contactInfo as JSON strings and decode them
    String? educationJson = prefs.getString('education');
    String? experienceJson = prefs.getString('experience');
    String? locationJson = prefs.getString('location');
    String? contactInfoJson = prefs.getString('contactInfo');

    // Ensure location and contactInfo are decoded as Map<String, dynamic>
    Map<String, dynamic> locationData = {
      'city': '',
      'postalCode': '',
      'state': '',
      'country': '',
    };
    Map<String, dynamic> contactInfoData = {
      'email': '',
      'contactNo': '',
      'website': '',
    };

    try {
      if (locationJson != null && locationJson.isNotEmpty) {
        final decodedLocation = jsonDecode(locationJson);
        if (decodedLocation is Map<String, dynamic>) {
          locationData = decodedLocation;
        }
      }
    } catch (e) {
      // Handle JSON decode error by resetting to default
      locationData = {'city': '', 'postalCode': '', 'state': '', 'country': ''};
    }

    try {
      if (contactInfoJson != null && contactInfoJson.isNotEmpty) {
        final decodedContactInfo = jsonDecode(contactInfoJson);
        if (decodedContactInfo is Map<String, dynamic>) {
          contactInfoData = decodedContactInfo;
        }
      }
    } catch (e) {
      // Handle JSON decode error by resetting to default
      contactInfoData = {'email': '', 'contactNo': '', 'website': ''};
    }

    _profile = {
      'headline': prefs.getString('headline') ?? '',
      'about': prefs.getString('about') ?? '',
      'skills': prefs.getString('skills') ?? '',
      'education': educationJson != null && educationJson.isNotEmpty
          ? jsonDecode(educationJson) as List<dynamic>? ?? []
          : [],
      'experience': experienceJson != null && experienceJson.isNotEmpty
          ? jsonDecode(experienceJson) as List<dynamic>? ?? []
          : [],
      'location': locationData,
      'contactInfo': contactInfoData,
    };
    notifyListeners();
  }

  Future<void> updateProfileImage(File image, String path) async {
    final prefs = await SharedPreferences.getInstance();
    _profileImage = image;
    _profileImagePath = path;
    await prefs.setString('profile_image_path', path);
    notifyListeners();
  }

  Future<void> updateBannerImage(File image, String path) async {
    final prefs = await SharedPreferences.getInstance();
    _bannerImage = image;
    _bannerImagePath = path;
    await prefs.setString('banner_image_path', path);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    _profile = profile;

    // Encode education, experience, location, and contactInfo as JSON strings before saving
    String educationJson = jsonEncode(profile['education'] ?? []);
    String experienceJson = jsonEncode(profile['experience'] ?? []);
    String locationJson = jsonEncode(
      profile['location'] ??
          {'city': '', 'postalCode': '', 'state': '', 'country': ''},
    );
    String contactInfoJson = jsonEncode(
      profile['contactInfo'] ?? {'email': '', 'contactNo': '', 'website': ''},
    );

    await prefs.setString('headline', profile['headline'] ?? '');
    await prefs.setString('about', profile['about'] ?? '');
    await prefs.setString('skills', profile['skills'] ?? '');
    await prefs.setString('education', educationJson);
    await prefs.setString('experience', experienceJson);
    await prefs.setString('location', locationJson);
    await prefs.setString('contactInfo', contactInfoJson);
    notifyListeners();
  }

  Future<void> updateProfileField(String field, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    _profile ??= {
      'headline': '',
      'about': '',
      'skills': '',
      'education': [],
      'experience': [],
      'location': {'city': '', 'postalCode': '', 'state': '', 'country': ''},
      'contactInfo': {'email': '', 'contactNo': '', 'website': ''},
    };
    _profile![field] = value;

    if (field == 'education') {
      await prefs.setString('education', jsonEncode(value));
    } else if (field == 'experience') {
      await prefs.setString('experience', jsonEncode(value));
    } else if (field == 'location') {
      await prefs.setString('location', jsonEncode(value));
    } else if (field == 'contactInfo') {
      await prefs.setString('contactInfo', jsonEncode(value));
    } else {
      await prefs.setString(field, value.toString());
    }
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _username = username;
    await prefs.setString('username', username);
    notifyListeners();
  }

  Future<void> updateEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _email = email;
    await prefs.setString('email', email);
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final profileData = await _apiService.getProfile();
      _profile = profileData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _profile = {
      'headline': '',
      'about': '',
      'skills': '',
      'education': [],
      'experience': [],
      'location': {'city': '', 'postalCode': '', 'state': '', 'country': ''},
      'contactInfo': {'email': '', 'contactNo': '', 'website': ''},
    };
    _username = null;
    _email = null;
    _profileImage = null;
    _profileImagePath = null;
    _bannerImage = null;
    _bannerImagePath = null;

    await prefs.remove('headline');
    await prefs.remove('about');
    await prefs.remove('skills');
    await prefs.remove('education');
    await prefs.remove('experience');
    await prefs.remove('location');
    await prefs.remove('contactInfo');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('profile_image_path');
    await prefs.remove('banner_image_path');
    notifyListeners();
  }
}
