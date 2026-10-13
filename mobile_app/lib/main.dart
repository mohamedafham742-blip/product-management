import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const ProductManagementApp());
}

class ProductManagementApp extends StatelessWidget {
  const ProductManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D3835),
          primary: const Color(0xFF3D3835),
          surface: const Color(0xFFFAF7F4),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: ApiService().isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
