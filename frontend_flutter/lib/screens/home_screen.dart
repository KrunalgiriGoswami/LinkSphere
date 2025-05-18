import 'package:flutter/material.dart';
import 'package:frontend_flutter/screens/edit_post_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart'
    as timeago; // Add this package for relative time
import 'package:share_plus/share_plus.dart';
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
  // Add a map to track which posts have their comments expanded
  final Map<int, bool> _expandedComments = {};
  // Add a map to store comments for each post
  final Map<int, List<Map<String, dynamic>>> _postComments = {};
  // Add a map to track loading state for each post's comments
  final Map<int, bool> _loadingComments = {};
  // Add a map for comment text controllers
  final Map<int, TextEditingController> _commentControllers = {};
  // Add a map to track liked posts
  final Map<int, bool> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      postsProvider.fetchPosts().then((_) {
        // Initialize liked posts map based on user's likes
        if (postsProvider.posts != null) {
          for (var post in postsProvider.posts!) {
            _likedPosts[post['id']] = post['isLikedByUser'] ?? false;
          }
        }
      });

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
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) =>
                                      _handlePostAction(value, post),
                                  itemBuilder: (BuildContext context) {
                                    final List<PopupMenuEntry<String>> items = [
                                      PopupMenuItem<String>(
                                        value: 'save',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.bookmark_border),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Save Post',
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];

                                    // Only show edit and delete options for user's own posts
                                    if (post['username'] ==
                                        profileProvider.username) {
                                      items.addAll([
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Edit Post',
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Delete Post',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }
                                    return items;
                                  },
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  icon: _likedPosts[post['id']] ?? false
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  label: '${post['likesCount'] ?? 0}',
                                  onPressed: () async {
                                    try {
                                      final bool success = await postsProvider
                                          .likePost(post['id']);
                                      if (success) {
                                        setState(() {
                                          _likedPosts[post['id']] =
                                              !(_likedPosts[post['id']] ??
                                                  false);
                                        });
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to like post: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.comment_outlined,
                                  label: '${post['commentsCount'] ?? 0}',
                                  onPressed: () => _toggleComments(post['id']),
                                ),
                                _buildActionButton(
                                  icon: Icons.share_outlined,
                                  label: 'Share',
                                  onPressed: () => _sharePost(post),
                                ),
                              ],
                            ),
                          ),

                          // Add expandable comments section
                          if (_expandedComments[post['id']] ?? false) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Comments list
                                  if (_loadingComments[post['id']] ?? false)
                                    const Center(
                                        child: CircularProgressIndicator())
                                  else if (_postComments[post['id']] !=
                                      null) ...[
                                    for (var comment
                                        in _postComments[post['id']]!)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage: profileProvider
                                                          .profileImage !=
                                                      null
                                                  ? FileImage(profileProvider
                                                      .profileImage!)
                                                  : const AssetImage(
                                                      'assets/images/default_profile.png',
                                                    ) as ImageProvider,
                                              backgroundColor: AppColors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    comment['content'] ?? '',
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                  Text(
                                                    _getRelativeTime(
                                                        comment['createdAt']),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],

                                  // Comment input field
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentControllers[
                                                  post['id']] ??=
                                              TextEditingController(),
                                          decoration: InputDecoration(
                                            hintText: 'Write a comment...',
                                            hintStyle: GoogleFonts.poppins(),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.send),
                                        onPressed: () => _addComment(
                                          post['id'],
                                          _commentControllers[post['id']]
                                                  ?.text ??
                                              '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  // Add this method to handle comment expansion
  void _toggleComments(int postId) async {
    setState(() {
      _expandedComments[postId] = !(_expandedComments[postId] ?? false);
      if (_expandedComments[postId] == true && _postComments[postId] == null) {
        _loadingComments[postId] = true;
      }
    });

    if (_expandedComments[postId] == true && _postComments[postId] == null) {
      try {
        final comments = await _apiService.getPostComments(postId);
        setState(() {
          _postComments[postId] = comments;
          _loadingComments[postId] = false;
        });
      } catch (e) {
        setState(() {
          _loadingComments[postId] = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load comments: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Add this method to handle adding new comments
  Future<void> _addComment(int postId, String comment) async {
    if (comment.trim().isEmpty) return;

    try {
      await _apiService.addComment(postId, comment);
      // Refresh comments for this post
      final comments = await _apiService.getPostComments(postId);
      setState(() {
        _postComments[postId] = comments;
      });
      // Clear the comment input
      _commentControllers[postId]?.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the share post method
  Future<void> _sharePost(Map<String, dynamic> post) async {
    try {
      String shareText = '';

      // Add post description if available
      if (post['description'] != null &&
          post['description'].toString().isNotEmpty) {
        shareText += post['description'].toString() + '\n\n';
      }

      // Add post author
      shareText += 'Posted by ${post['username'] ?? 'Unknown User'}\n';

      // Add media URLs if available
      final mediaUrls = post['mediaUrls']?.toString().split(',') ?? [];
      final filteredMediaUrls =
          mediaUrls.where((url) => url.isNotEmpty).toList();

      if (filteredMediaUrls.isNotEmpty) {
        shareText += '\nMedia: ${filteredMediaUrls.join('\n')}';
      }

      // Add app attribution
      shareText += '\n\nShared via LinkSphere';

      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to handle post actions
  Future<void> _handlePostAction(
      String action, Map<String, dynamic> post) async {
    switch (action) {
      case 'save':
        // TODO: Implement save post functionality
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Post saved successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'edit':
        // Navigate to edit post screen
        final bool? edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditPostScreen(post: post),
          ),
        );
        if (edited == true) {
          // Refresh posts list after editing
          final postsProvider =
              Provider.of<PostsProvider>(context, listen: false);
          await postsProvider.fetchPosts();
        }
        break;
      case 'delete':
        // Show confirmation dialog before deleting
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Delete Post',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this post?',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          try {
            final postsProvider =
                Provider.of<PostsProvider>(context, listen: false);
            await postsProvider.deletePost(post['id']);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Post deleted successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to delete post: ${e.toString()}',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }
}
