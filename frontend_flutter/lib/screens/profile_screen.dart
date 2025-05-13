import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend_flutter/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/animated_scale_button.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _headlineController = TextEditingController();
  final _aboutController = TextEditingController();
  final _skillsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<ProfileProvider>(context, listen: false).profile;
    _headlineController.text = profile?['headline'] ?? '';
    _aboutController.text = profile?['about'] ?? '';
    _skillsController.text = profile?['skills'] ?? '';
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        final imageFile = File(pickedFile.path);
        await profileProvider.updateProfileImage(imageFile, pickedFile.path);
        Fluttertoast.showToast(
          msg: 'Profile image updated',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking profile image: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        final imageFile = File(pickedFile.path);
        await profileProvider.updateBannerImage(imageFile, pickedFile.path);
        Fluttertoast.showToast(
          msg: 'Banner image updated',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking banner image: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final profileData = {
          'headline': _headlineController.text,
          'about': _aboutController.text,
          'skills': _skillsController.text,
        };
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        if (profileProvider.profile == null) {
          await _apiService.createProfile(
            _headlineController.text,
            _aboutController.text,
            _skillsController.text,
          );
        } else {
          await _apiService.updateProfile(
            _headlineController.text,
            _aboutController.text,
            _skillsController.text,
          );
        }
        await profileProvider.updateProfile(profileData);
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Profile saved successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Failed to save profile: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlue,
            elevation: 4,
            shadowColor: AppColors.primaryBlue.withOpacity(0.3),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FadeInAnimation(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: _pickBannerImage,
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                    image:
                                        profileProvider.bannerImage != null
                                            ? DecorationImage(
                                              image: FileImage(
                                                profileProvider.bannerImage!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : const DecorationImage(
                                              image: AssetImage(
                                                'assets/images/default_banner.png',
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: AppColors.white.withOpacity(0.8),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 100,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage:
                                          profileProvider.profileImage != null
                                              ? FileImage(
                                                profileProvider.profileImage!,
                                              )
                                              : const AssetImage(
                                                    'assets/images/default_profile.png',
                                                  )
                                                  as ImageProvider,
                                      backgroundColor: AppColors.white,
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: AppColors.white.withOpacity(
                                            0.8,
                                          ),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 60,
                          ), // Space for profile image overlap
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      profileProvider.username ?? 'User',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isEditing ? Icons.close : Icons.edit,
                                        color: AppColors.accentTeal,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = !_isEditing;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _isEditing
                                    ? _buildEditForm()
                                    : _buildViewMode(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildViewMode() {
    final profile = Provider.of<ProfileProvider>(context).profile;
    return FadeInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.title, color: AppColors.accentTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Headline',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile?['headline'] ?? 'No headline set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info, color: AppColors.accentTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'About',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile?['about'] ?? 'No about section set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star, color: AppColors.accentTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Skills',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile?['skills'] ?? 'No skills set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return FadeInAnimation(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _headlineController,
              decoration: InputDecoration(
                labelText: 'Headline',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                prefixIcon: Icon(Icons.title, color: AppColors.accentTeal),
              ),
              validator: (value) {
                if (value != null && value.length > 100) {
                  return 'Headline must be less than 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              decoration: InputDecoration(
                labelText: 'About',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                prefixIcon: Icon(Icons.info, color: AppColors.accentTeal),
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'About section must be less than 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skillsController,
              decoration: InputDecoration(
                labelText: 'Skills (comma-separated)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                prefixIcon: Icon(Icons.star, color: AppColors.accentTeal),
              ),
              validator: (value) {
                if (value != null && value.length > 255) {
                  return 'Skills must be less than 255 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AnimatedScaleButton(
              onPressed: _saveProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryBlue,
                ),
                child: Text(
                  'Save Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
