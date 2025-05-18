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

    // Migrate string-based education/experience to list format if needed
    _migrateProfileData();
  }

  void _migrateProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile == null) return;

    Map<String, dynamic> updatedProfile = Map.from(profile);

    // Migrate education
    if (profile['education'] is String &&
        profile['education'].toString().isNotEmpty) {
      updatedProfile['education'] = [
        {
          'degree': profile['education'],
          'university': '',
          'grade': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    } else if (profile['education'] == null ||
        (profile['education'] is String &&
            profile['education'].toString().isEmpty)) {
      updatedProfile['education'] = [];
    }

    // Migrate experience
    if (profile['experience'] is String &&
        profile['experience'].toString().isNotEmpty) {
      updatedProfile['experience'] = [
        {
          'company': profile['experience'],
          'role': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    } else if (profile['experience'] == null ||
        (profile['experience'] is String &&
            profile['experience'].toString().isEmpty)) {
      updatedProfile['experience'] = [];
    }

    // Migrate location if it's a string
    if (profile['location'] is String &&
        profile['location'].toString().isNotEmpty) {
      updatedProfile['location'] = {
        'city': profile['location'],
        'postalCode': '',
        'state': '',
        'country': '',
      };
    } else if (profile['location'] == null) {
      updatedProfile['location'] = {
        'city': '',
        'postalCode': '',
        'state': '',
        'country': '',
      };
    }

    // Migrate website to contactInfo
    if (profile['contactInfo'] == null && profile['website'] != null) {
      updatedProfile['contactInfo'] = {
        'email': '',
        'contactNo': '',
        'website': profile['website'] ?? '',
      };
      updatedProfile.remove('website');
    } else if (profile['contactInfo'] == null) {
      updatedProfile['contactInfo'] = {
        'email': '',
        'contactNo': '',
        'website': '',
      };
    }

    // Update ProfileProvider with the migrated data
    profileProvider.updateProfile(updatedProfile);
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
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );

        // Ensure education and experience are lists
        List<dynamic> educationList;
        if (profileProvider.profile?['education'] is List) {
          educationList =
              profileProvider.profile?['education'] as List<dynamic>? ?? [];
        } else if (profileProvider.profile?['education'] is String &&
            (profileProvider.profile?['education'] as String).isNotEmpty) {
          educationList = [
            {
              'degree': profileProvider.profile?['education'],
              'university': '',
              'grade': '',
              'startDate': '',
              'endDate': '',
            },
          ];
        } else {
          educationList = [];
        }

        List<dynamic> experienceList;
        if (profileProvider.profile?['experience'] is List) {
          experienceList =
              profileProvider.profile?['experience'] as List<dynamic>? ?? [];
        } else if (profileProvider.profile?['experience'] is String &&
            (profileProvider.profile?['experience'] as String).isNotEmpty) {
          experienceList = [
            {
              'company': profileProvider.profile?['experience'],
              'role': '',
              'startDate': '',
              'endDate': '',
            },
          ];
        } else {
          experienceList = [];
        }

        final profileData = {
          'headline': _headlineController.text,
          'about': _aboutController.text,
          'skills': _skillsController.text,
          'education': educationList,
          'experience': experienceList,
          'location': profileProvider.profile?['location'] ??
              {'city': '', 'postalCode': '', 'state': '', 'country': ''},
          'contactInfo': profileProvider.profile?['contactInfo'] ??
              {'email': '', 'contactNo': '', 'website': ''},
        };

        if (profileProvider.profile == null ||
            profileProvider.profile!.isEmpty) {
          await _apiService.createProfile(
            _headlineController.text,
            _aboutController.text,
            _skillsController.text,
            educationList,
            experienceList,
            profileData['location'] as Map<String, dynamic>,
            profileData['contactInfo'] as Map<String, dynamic>,
          );
        } else {
          await _apiService.updateProfile(
            _headlineController.text,
            _aboutController.text,
            _skillsController.text,
            educationList,
            experienceList,
            profileData['location'] as Map<String, dynamic>,
            profileData['contactInfo'] as Map<String, dynamic>,
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

  Future<void> _showEducationDialog({
    Map<String, dynamic>? existingEntry,
    int? index,
  }) async {
    final degreeController = TextEditingController(
      text: existingEntry?['degree'] ?? '',
    );
    final universityController = TextEditingController(
      text: existingEntry?['university'] ?? '',
    );
    final gradeController = TextEditingController(
      text: existingEntry?['grade'] ?? '',
    );
    final startDateController = TextEditingController(
      text: existingEntry?['startDate'] ?? '',
    );
    final endDateController = TextEditingController(
      text: existingEntry?['endDate'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingEntry == null ? 'Add Education' : 'Edit Education',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: degreeController,
                  decoration: InputDecoration(
                    labelText: 'Degree (e.g., BE, B Tech)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: universityController,
                  decoration: InputDecoration(
                    labelText: 'University Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gradeController,
                  decoration: InputDecoration(
                    labelText: 'Grade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date (MM/YYYY)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date (MM/YYYY or Present)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final entry = {
                  'degree': degreeController.text,
                  'university': universityController.text,
                  'grade': gradeController.text,
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                };
                final profileProvider = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );
                List<dynamic> educationList = List.from(
                  profileProvider.profile?['education'] ?? [],
                );
                if (index != null) {
                  educationList[index] = entry;
                } else {
                  educationList.add(entry);
                }
                profileProvider.updateProfileField('education', educationList);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteEducation(int index) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    List<dynamic> educationList = List.from(
      profileProvider.profile?['education'] ?? [],
    );
    if (index >= 0 && index < educationList.length) {
      educationList.removeAt(index);
      profileProvider.updateProfileField('education', educationList);
    }
  }

  Future<void> _showExperienceDialog({
    Map<String, dynamic>? existingEntry,
    int? index,
  }) async {
    final companyController = TextEditingController(
      text: existingEntry?['company'] ?? '',
    );
    final roleController = TextEditingController(
      text: existingEntry?['role'] ?? '',
    );
    final startDateController = TextEditingController(
      text: existingEntry?['startDate'] ?? '',
    );
    final endDateController = TextEditingController(
      text: existingEntry?['endDate'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingEntry == null ? 'Add Experience' : 'Edit Experience',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: 'Role/Position',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date (MM/YYYY)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date (MM/YYYY or Present)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final entry = {
                  'company': companyController.text,
                  'role': roleController.text,
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                };
                final profileProvider = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );
                List<dynamic> experienceList = List.from(
                  profileProvider.profile?['experience'] ?? [],
                );
                if (index != null) {
                  experienceList[index] = entry;
                } else {
                  experienceList.add(entry);
                }
                profileProvider.updateProfileField(
                  'experience',
                  experienceList,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteExperience(int index) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    List<dynamic> experienceList = List.from(
      profileProvider.profile?['experience'] ?? [],
    );
    if (index >= 0 && index < experienceList.length) {
      experienceList.removeAt(index);
      profileProvider.updateProfileField('experience', experienceList);
    }
  }

  Future<void> _showLocationDialog() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final location =
        profileProvider.profile?['location'] as Map<String, dynamic>? ?? {};
    final cityController = TextEditingController(text: location['city'] ?? '');
    final postalCodeController = TextEditingController(
      text: location['postalCode'] ?? '',
    );
    final stateController = TextEditingController(
      text: location['state'] ?? '',
    );
    final countryController = TextEditingController(
      text: location['country'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Location',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'Postal Code / Zip Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final updatedLocation = {
                  'city': cityController.text,
                  'postalCode': postalCodeController.text,
                  'state': stateController.text,
                  'country': countryController.text,
                };
                profileProvider.updateProfileField('location', updatedLocation);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showContactInfoDialog() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final contactInfo =
        profileProvider.profile?['contactInfo'] as Map<String, dynamic>? ?? {};
    final emailController = TextEditingController(
      text: contactInfo['email'] ?? '',
    );
    final contactNoController = TextEditingController(
      text: contactInfo['contactNo'] ?? '',
    );
    final websiteController = TextEditingController(
      text: contactInfo['website'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Contact Info',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactNoController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  decoration: InputDecoration(
                    labelText: 'Website/Link',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final updatedContactInfo = {
                  'email': emailController.text,
                  'contactNo': contactNoController.text,
                  'website': websiteController.text,
                };
                profileProvider.updateProfileField(
                  'contactInfo',
                  updatedContactInfo,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          body: _isLoading
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
                                  image: profileProvider.bannerImage != null
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
                                              ) as ImageProvider,
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
                              _isEditing ? _buildEditForm() : _buildViewMode(),
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
    final skillsString = profile?['skills']?.toString() ?? '';
    final skillsList = skillsString
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    // Safely handle education and experience, ensuring they are lists
    List<dynamic> educationList;
    if (profile?['education'] is List) {
      educationList = profile?['education'] as List<dynamic>? ?? [];
    } else if (profile?['education'] is String &&
        (profile?['education'] as String).isNotEmpty) {
      educationList = [
        {
          'degree': profile?['education'],
          'university': '',
          'grade': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    } else {
      educationList = [];
    }

    List<dynamic> experienceList;
    if (profile?['experience'] is List) {
      experienceList = profile?['experience'] as List<dynamic>? ?? [];
    } else if (profile?['experience'] is String &&
        (profile?['experience'] as String).isNotEmpty) {
      experienceList = [
        {
          'company': profile?['experience'],
          'role': '',
          'startDate': '',
          'endDate': '',
        },
      ];
    } else {
      experienceList = [];
    }

    // Handle location as a map
    final location = profile?['location'] as Map<String, dynamic>? ?? {};
    final city = location['city'] ?? '';
    final postalCode = location['postalCode'] ?? '';
    final state = location['state'] ?? '';
    final country = location['country'] ?? '';

    // Format the address as "city - postalCode, state, country"
    List<String> addressParts = [];
    if (city.isNotEmpty) addressParts.add(city);
    if (postalCode.isNotEmpty) addressParts.add(postalCode);
    String cityPostal = addressParts.join(' - ');
    addressParts = [];
    if (cityPostal.isNotEmpty) addressParts.add(cityPostal);
    if (state.isNotEmpty) addressParts.add(state);
    if (country.isNotEmpty) addressParts.add(country);
    final formattedAddress = addressParts.join(', ');

    // Handle contact info as a map
    final contactInfo = profile?['contactInfo'] as Map<String, dynamic>? ?? {};
    final email = contactInfo['email'] ?? '';
    final contactNo = contactInfo['contactNo'] ?? '';
    final website = contactInfo['website'] ?? '';

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
          skillsList.isEmpty
              ? Text(
                  'No skills set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: skillsList.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentTeal.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school,
                      color: AppColors.accentTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Education',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.accentTeal),
                onPressed: () => _showEducationDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          educationList.isEmpty
              ? Text(
                  'No education set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  children: educationList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final edu = entry.value as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${edu['degree']} at ${edu['university']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Grade: ${edu['grade']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${edu['startDate']} - ${edu['endDate']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.accentTeal,
                              ),
                              onPressed: () => _showEducationDialog(
                                existingEntry: edu,
                                index: index,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteEducation(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.work, color: AppColors.accentTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Experience',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.accentTeal),
                onPressed: () => _showExperienceDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          experienceList.isEmpty
              ? Text(
                  'No experience set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  children: experienceList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exp = entry.value as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${exp['role']} at ${exp['company']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exp['startDate']} - ${exp['endDate']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.accentTeal,
                              ),
                              onPressed: () => _showExperienceDialog(
                                existingEntry: exp,
                                index: index,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteExperience(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.accentTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.accentTeal),
                onPressed: () => _showLocationDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          (city.isEmpty &&
                  postalCode.isEmpty &&
                  state.isEmpty &&
                  country.isEmpty)
              ? Text(
                  'No location set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentTeal.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedAddress.isEmpty
                                ? 'No location set'
                                : formattedAddress,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.contact_mail,
                    color: AppColors.accentTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Info',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.accentTeal),
                onPressed: () => _showContactInfoDialog(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          (email.isEmpty && contactNo.isEmpty && website.isEmpty)
              ? Text(
                  'No contact info set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentTeal.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (email.isNotEmpty &&
                            (contactNo.isNotEmpty || website.isNotEmpty))
                          const SizedBox(height: 8),
                        if (contactNo.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  contactNo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (contactNo.isNotEmpty && website.isNotEmpty)
                          const SizedBox(height: 8),
                        if (website.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.link,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  website,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 32), // Added space at the bottom
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
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
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
                prefixIcon:
                    const Icon(Icons.title, color: AppColors.accentTeal),
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
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
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
                prefixIcon: const Icon(Icons.info, color: AppColors.accentTeal),
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
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
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
                prefixIcon: const Icon(Icons.star, color: AppColors.accentTeal),
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
