import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  String? _username;
  String? _email;
  File? _profileImage;
  String? _profileImagePath;
  File? _bannerImage;
  String? _bannerImagePath;
  Map<String, dynamic>? _profile;

  String? get username => _username;
  String? get email => _email;
  File? get profileImage => _profileImage;
  String? get profileImagePath => _profileImagePath;
  File? get bannerImage => _bannerImage;
  String? get bannerImagePath => _bannerImagePath;
  Map<String, dynamic>? get profile => _profile;

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
    _profile = {
      'headline': prefs.getString('headline') ?? '',
      'about': prefs.getString('about') ?? '',
      'skills': prefs.getString('skills') ?? '',
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
    await prefs.setString('headline', profile['headline']);
    await prefs.setString('about', profile['about']);
    await prefs.setString('skills', profile['skills']);
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _username = username;
    await prefs.setString('username', username);
    notifyListeners();
  }
}
