import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/animated_scale_button.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../providers/profile_provider.dart';
import 'post_screen.dart';
import 'my_networks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

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
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('profile_image_path');
      await prefs.clear();
      if (profileImagePath != null) {
        await prefs.setString('profile_image_path', profileImagePath);
      }
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
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyNetworksScreen()),
        );
        break;
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
            leading: Builder(
              builder:
                  (context) => GestureDetector(
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
                          backgroundImage:
                              profileProvider.profileImage != null
                                  ? FileImage(profileProvider.profileImage!)
                                  : const AssetImage(
                                        'assets/images/default_profile.png',
                                      )
                                      as ImageProvider,
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
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 14,
                ),
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
                                icon: Icon(
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
                                                  profileProvider.profileImage!,
                                                )
                                                : const AssetImage(
                                                      'assets/images/default_profile.png',
                                                    )
                                                    as ImageProvider,
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
                              Icon(
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
          body: Center(
            child: Text(
              'Welcome to LinkSphere!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
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
            profileProvider.profile?['headline'] ?? 'No headline set',
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
            profileProvider.profile?['about'] ?? 'No about section set',
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
            profileProvider.profile?['skills'] ?? 'No skills set',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
