import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final List<File> _selectedMedia = [];
  final List<String> _mediaTypes = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.profile == null) {
        await profileProvider.fetchProfile();
      }
      if (!mounted) return;

      if (profileProvider.error != null) {
        _showErrorToast('Error loading profile: ${profileProvider.error}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorToast('Error loading profile: $e');
    }
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _selectedMedia.add(File(image.path));
          _mediaTypes.add('image');
        });
      }
    } catch (e) {
      _showErrorToast('Error picking image: $e');
    }
  }

  Future<void> _pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: source);

      if (video != null) {
        setState(() {
          _selectedMedia.add(File(video.path));
          _mediaTypes.add('video');
        });
      }
    } catch (e) {
      _showErrorToast('Error picking video: $e');
    }
  }

  void _showMediaPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Media',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Photo from Gallery', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Take Photo', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: Text('Video from Gallery', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text('Record Video', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(source: ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      _mediaTypes.removeAt(index);
    });
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  Future<void> _createPost() async {
    if (_descriptionController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      _showErrorToast('Please enter a description or add media');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      String? profilePicturePath;

      // Get profile picture path - either from local file or network
      if (profileProvider.profileImage != null) {
        profilePicturePath = profileProvider.profileImagePath;
      }

      // Get username
      final username = profileProvider.username ?? 'User';

      // Upload media files and get URLs
      List<String> mediaUrls = [];
      for (int i = 0; i < _selectedMedia.length; i++) {
        try {
          String url = await _apiService.uploadMedia(_selectedMedia[i]);
          mediaUrls.add(url);
        } catch (e) {
          _showErrorToast('Error uploading media ${i + 1}: ${e.toString()}');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Create post with profile picture and username
      await _apiService.createPost(
        _descriptionController.text.trim(),
        mediaUrls.join(','),
        _mediaTypes.join(','),
        profilePicturePath,
        username,
      );

      if (!mounted) return;

      _showSuccessToast('Post created successfully!');
      Navigator.pop(
          context, true); // Pass true to indicate successful post creation
    } catch (e) {
      if (!mounted) return;
      _showErrorToast('Error creating post: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _createPost,
              child: Text(
                'Share',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.white),
            ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (profileProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
            );
          }

          return FadeInAnimation(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: profileProvider.profileImage != null
                            ? FileImage(profileProvider.profileImage!)
                            : const AssetImage(
                                    'assets/images/default_profile.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileProvider.username ?? 'User',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (profileProvider.profile?['headline'] != null)
                            Text(
                              profileProvider.profile!['headline'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description TextField
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'What do you want to share?',
                      hintStyle:
                          GoogleFonts.poppins(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Media Preview
                  if (_selectedMedia.isNotEmpty) ...[
                    Text(
                      'Selected Media',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedMedia.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: AppColors.primaryBlue),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _mediaTypes[index] == 'image'
                                    ? Image.file(_selectedMedia[index],
                                        fit: BoxFit.cover)
                                    : Center(
                                        child: Icon(
                                          _mediaTypes[index] == 'video'
                                              ? Icons.video_file
                                              : Icons.insert_drive_file,
                                          size: 40,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeMedia(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  // Media Upload Button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showMediaPickerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_photo_alternate,
                          color: Colors.white),
                      label: Text(
                        'Add Media',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
