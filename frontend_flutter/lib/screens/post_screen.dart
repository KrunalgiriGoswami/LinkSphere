import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations.dart';
import '../core/constants.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({super.key});

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
      ),
      body: FadeInAnimation(
        child: Center(
          child: Text(
            'Post creation screen (to be implemented)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
