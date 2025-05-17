import 'package:flutter/material.dart';
import 'package:frontend_flutter/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';

import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/post_screen.dart';
import 'screens/my_networks_screen.dart';
import 'providers/profile_provider.dart';
import 'providers/posts_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
      ],
      child: MaterialApp(
        title: 'LinkSphere',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/post': (context) => const PostScreen(),
          '/networks': (context) => const MyNetworksScreen(),
        },
      ),
    );
  }
}
