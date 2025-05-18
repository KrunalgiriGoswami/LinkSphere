import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart'
    as timeago; // Add this package for relative time
import '../core/animated_scale_button.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../providers/profile_provider.dart';
import 'post_screen.dart';
import 'my_networks_screen.dart';
import '../providers/posts_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      postsProvider.fetchPosts();

      // Also ensure profile data is loaded
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.fetchProfile();
    });
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('jwt_token');
    });
  }

  Future<void> _logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.white,
        );
      },
    );

    if (confirmLogout == true) {
      // Save profile image path before clearing data
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('profile_image_path');
      final bannerImagePath = prefs.getString('banner_image_path');
      final username = prefs.getString('username');
      final email = prefs.getString('email');

      // Store these values to restore after logout
      Map<String, String?> savedValues = {
        'profile_image_path': profileImagePath,
        'banner_image_path': bannerImagePath,
        'username': username,
        'email': email,
      };

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      // Clear all preferences
      await prefs.clear();

      // Restore saved values
      for (var entry in savedValues.entries) {
        if (entry.value != null) {
          await prefs.setString(entry.key, entry.value!);
        }
      }

      // Reload user data to reflect changes
      await profileProvider.fetchProfile();

      Navigator.pushReplacementNamed(context, '/login');
      Fluttertoast.showToast(
        msg: 'Logged out successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        final postsProvider =
            Provider.of<PostsProvider>(context, listen: false);
        postsProvider.fetchPosts();
        break;
      case 1:
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const PostScreen()),
        ).then((posted) {
          if (posted == true) {
            // Refresh posts list
            final postsProvider =
                Provider.of<PostsProvider>(context, listen: false);
            postsProvider.fetchPosts();
          }
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyNetworksScreen()),
        );
        break;
    }
  }

  // Convert timestamp string to relative time
  String _getRelativeTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Just now';
    }

    try {
      // Parse the timestamp - adjust this based on your actual timestamp format
      DateTime dateTime = DateTime.parse(timestamp);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Recently';
    }
  }

  // Add this method to get the full image URL
  String _getFullImageUrl(String path) {
    // Using the same base URL as defined in ApiService
    const baseUrl = 'http://10.0.2.2:8080';
    if (path.startsWith('http')) {
      return path;
    }
    return '$baseUrl$path';
  }

  Widget _buildAuthenticatedImage(String imageUrl) {
    return Image.network(
      _getFullImageUrl(imageUrl),
      fit: BoxFit.cover,
      headers:
          _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 40,
            ),
          ),
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
            leading: Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentTeal,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: profileProvider.profileImage != null
                          ? FileImage(profileProvider.profileImage!)
                          : const AssetImage(
                              'assets/images/default_profile.png',
                            ) as ImageProvider,
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            title: Container(
              height: 36,
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 14,
                ),
                onChanged: (value) {
                  final postsProvider =
                      Provider.of<PostsProvider>(context, listen: false);
                  if (value.isEmpty) {
                    postsProvider.fetchPosts();
                  } else {
                    postsProvider.searchPosts(value);
                  }
                },
              ),
            ),
            titleSpacing: 0,
          ),
          drawer: Drawer(
            child: FadeInAnimation(
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // Close drawer
                                  Navigator.pushNamed(context, '/profile');
                                },
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context); // Close drawer
                                      Navigator.pushNamed(context, '/profile');
                                    },
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
                                        radius: 30,
                                        backgroundImage:
                                            profileProvider.profileImage != null
                                                ? FileImage(
                                                    profileProvider
                                                        .profileImage!,
                                                  )
                                                : const AssetImage(
                                                    'assets/images/default_profile.png',
                                                  ) as ImageProvider,
                                        backgroundColor: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          profileProvider.username ?? 'User',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          profileProvider.email ??
                                              'email@example.com',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: AppColors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Divider(
                              color: AppColors.accentTeal.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            _buildViewMode(profileProvider),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppColors.primaryBlue, Colors.blue[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedScaleButton(
                        onPressed: _logout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout,
                                color: AppColors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Consumer<PostsProvider>(
            builder: (context, postsProvider, child) {
              if (postsProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (postsProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading posts: ${postsProvider.error}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => postsProvider.fetchPosts(),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (postsProvider.posts == null || postsProvider.posts!.isEmpty) {
                return Center(
                  child: Text(
                    'No posts yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => postsProvider.fetchPosts(),
                child: ListView.builder(
                  itemCount: postsProvider.posts!.length,
                  itemBuilder: (context, index) {
                    final post = postsProvider.posts![index];
                    final mediaUrls =
                        post['mediaUrls']?.toString().split(',') ?? [];
                    final mediaTypes =
                        post['mediaTypes']?.toString().split(',') ?? [];

                    // Filter out empty strings from the lists
                    final filteredMediaUrls =
                        mediaUrls.where((url) => url.isNotEmpty).toList();
                    final filteredMediaTypes =
                        mediaTypes.where((type) => type.isNotEmpty).toList();

                    // Get the current user's profile image for consistency
                    final userProfileImage = profileProvider.profileImage;
                    final userName = profileProvider.username ?? 'User';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post Header
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Use the current user's profile image if the post is from the current user
                                // Otherwise use the post's profile picture or default
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: (post['profilePicture'] !=
                                              null &&
                                          post['profilePicture']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(
                                          _getFullImageUrl(
                                              post['profilePicture']),
                                          headers: _authToken != null
                                              ? {
                                                  'Authorization':
                                                      'Bearer $_authToken'
                                                }
                                              : null,
                                        )
                                      : (userProfileImage != null
                                          ? FileImage(userProfileImage)
                                          : const AssetImage(
                                                  'assets/images/default_profile.png')
                                              as ImageProvider),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Posted ${_getRelativeTime(post['createdAt'])}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Post Content
                          if (post['description'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                post['description'],
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),

                          // Media Content
                          if (filteredMediaUrls.isNotEmpty)
                            Container(
                              height: 250,
                              width: double.infinity,
                              child: PageView.builder(
                                itemCount: filteredMediaUrls.length,
                                itemBuilder: (context, mediaIndex) {
                                  final mediaUrl =
                                      filteredMediaUrls[mediaIndex];
                                  final mediaType =
                                      mediaIndex < filteredMediaTypes.length
                                          ? filteredMediaTypes[mediaIndex]
                                          : 'image';

                                  if (mediaType == 'image') {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            _buildAuthenticatedImage(mediaUrl),
                                      ),
                                    );
                                  } else if (mediaType == 'video') {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),

                          // Post Actions
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  icon: Icons.thumb_up,
                                  label: '${post['likesCount'] ?? 0}',
                                  onPressed: () =>
                                      postsProvider.likePost(post['id']),
                                ),
                                _buildActionButton(
                                  icon: Icons.comment,
                                  label: '${post['commentsCount'] ?? 0}',
                                  onPressed: () =>
                                      _showCommentDialog(context, post['id']),
                                ),
                                _buildActionButton(
                                  icon: Icons.bookmark,
                                  label: '${post['savesCount'] ?? 0}',
                                  onPressed: () =>
                                      postsProvider.savePost(post['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.white,
            onTap: _onNavBarTap,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'My Networks',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewMode(ProfileProvider profileProvider) {
    final skillsString = profileProvider.profile?['skills']?.toString() ?? '';
    final skillsList = skillsString
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    // Handle education and experience as lists
    if (profileProvider.profile?['education'] is List) {
    } else if (profileProvider.profile?['education'] is String &&
        (profileProvider.profile?['education'] as String).isNotEmpty) {
    } else {}

    if (profileProvider.profile?['experience'] is List) {
    } else if (profileProvider.profile?['experience'] is String &&
        (profileProvider.profile?['experience'] as String).isNotEmpty) {
    } else {}

    // Handle location as a map

    return FadeInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.title, color: AppColors.accentTeal, size: 20),
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
            profileProvider.profile?['headline'] ?? 'No headline set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info, color: AppColors.accentTeal, size: 20),
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
            profileProvider.profile?['about'] ?? 'No about section set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.accentTeal, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppColors.primaryBlue),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _showCommentDialog(BuildContext context, int postId) async {
    final commentController = TextEditingController();
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Fetch comments for this post
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    String? error;

    // Show dialog with loading state initially
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to fetch comments
            void fetchComments() async {
              try {
                comments = await _apiService.getPostComments(postId);
                setState(() {
                  isLoading = false;
                  error = null;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                  error = e.toString();
                });
              }
            }

            // Fetch comments when dialog opens
            if (isLoading && error == null) {
              fetchComments();
            }

            return AlertDialog(
              title: Text(
                'Comments',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Comments list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Error loading comments',
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            isLoading = true;
                                            error = null;
                                          });
                                          fetchComments();
                                        },
                                        child: Text(
                                          'Retry',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : comments.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No comments yet',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: comments.length,
                                      itemBuilder: (context, index) {
                                        final comment = comments[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            radius: 18,
                                            backgroundImage:
                                                profileProvider.profileImage !=
                                                        null
                                                    ? FileImage(profileProvider
                                                        .profileImage!)
                                                    : const AssetImage(
                                                        'assets/images/default_profile.png',
                                                      ) as ImageProvider,
                                            backgroundColor: AppColors.white,
                                          ),
                                          title: Text(
                                            comment['username'] ??
                                                'Unknown User',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment['content'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                _getRelativeTime(
                                                    comment['createdAt']),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                        );
                                      },
                                    ),
                    ),

                    // Comment input
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: profileProvider.profileImage != null
                              ? FileImage(profileProvider.profileImage!)
                              : const AssetImage(
                                  'assets/images/default_profile.png',
                                ) as ImageProvider,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: GoogleFonts.poppins(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue.withOpacity(0.5),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              // Show loading indicator
                              setState(() {
                                isLoading = true;
                              });

                              try {
                                // Add comment
                                await _apiService.addComment(
                                  postId,
                                  commentController.text.trim(),
                                );

                                // Clear input and refresh comments
                                commentController.clear();
                                fetchComments();

                                // Also refresh posts to update comment count
                                final postsProvider =
                                    Provider.of<PostsProvider>(context,
                                        listen: false);
                                postsProvider.fetchPosts();
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                  error = e.toString();
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
