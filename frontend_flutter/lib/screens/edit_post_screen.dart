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

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _descriptionController;
  final List<String> _existingMediaUrls = [];
  final List<String> _existingMediaTypes = [];
  final List<File> _newMediaFiles = [];
  final List<String> _newMediaTypes = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.post['description'] ?? '');

    // Parse existing media
    final mediaUrls = widget.post['mediaUrls']?.toString().split(',') ?? [];
    final mediaTypes = widget.post['mediaTypes']?.toString().split(',') ?? [];

    for (int i = 0; i < mediaUrls.length; i++) {
      if (mediaUrls[i].isNotEmpty) {
        _existingMediaUrls.add(mediaUrls[i]);
        if (i < mediaTypes.length && mediaTypes[i].isNotEmpty) {
          _existingMediaTypes.add(mediaTypes[i]);
        } else {
          _existingMediaTypes.add('image'); // Default to image
        }
      }
    }
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _newMediaFiles.add(File(image.path));
          _newMediaTypes.add('image');
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
          _newMediaFiles.add(File(video.path));
          _newMediaTypes.add('video');
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

  void _removeExistingMedia(int index) {
    setState(() {
      _existingMediaUrls.removeAt(index);
      if (index < _existingMediaTypes.length) {
        _existingMediaTypes.removeAt(index);
      }
    });
  }

  void _removeNewMedia(int index) {
    setState(() {
      _newMediaFiles.removeAt(index);
      if (index < _newMediaTypes.length) {
        _newMediaTypes.removeAt(index);
      }
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

  Future<void> _updatePost() async {
    if (_descriptionController.text.trim().isEmpty &&
        _existingMediaUrls.isEmpty &&
        _newMediaFiles.isEmpty) {
      _showErrorToast('Please enter a description or add media');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload new media files
      List<String> newMediaUrls = [];
      for (int i = 0; i < _newMediaFiles.length; i++) {
        try {
          String url = await _apiService.uploadMedia(_newMediaFiles[i]);
          newMediaUrls.add(url);
        } catch (e) {
          _showErrorToast('Error uploading media ${i + 1}: ${e.toString()}');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Combine existing and new media
      final allMediaUrls = [..._existingMediaUrls, ...newMediaUrls];
      final allMediaTypes = [..._existingMediaTypes, ..._newMediaTypes];

      // Update post
      await _apiService.updatePost(
        widget.post['id'],
        _descriptionController.text.trim(),
        allMediaUrls.join(','),
        allMediaTypes.join(','),
      );

      if (!mounted) return;

      _showSuccessToast('Post updated successfully!');
      Navigator.pop(context, true); // Pass true to indicate successful update
    } catch (e) {
      if (!mounted) return;
      _showErrorToast('Error updating post: ${e.toString()}');
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
          'Edit Post',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _updatePost,
              child: Text(
                'Save',
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
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Existing Media Preview
                  if (_existingMediaUrls.isNotEmpty) ...[
                    Text(
                      'Current Media',
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
                        itemCount: _existingMediaUrls.length,
                        itemBuilder: (context, index) {
                          final mediaUrl = _existingMediaUrls[index];
                          final mediaType = index < _existingMediaTypes.length
                              ? _existingMediaTypes[index]
                              : 'image';

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
                                child: mediaType == 'image'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          mediaUrl.startsWith('http')
                                              ? mediaUrl
                                              : 'http://10.0.2.2:8080${mediaUrl}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          mediaType == 'video'
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
                                  onTap: () => _removeExistingMedia(index),
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

                  // New Media Preview
                  if (_newMediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'New Media',
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
                        itemCount: _newMediaFiles.length,
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
                                child: _newMediaTypes[index] == 'image'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _newMediaFiles[index],
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          _newMediaTypes[index] == 'video'
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
                                  onTap: () => _removeNewMedia(index),
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
