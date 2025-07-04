import 'package:chungju_project/screens/home_screen.dart';
import 'package:chungju_project/screens/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/start_page.dart';

// ✅ dart-define으로 전달되는 값 받기
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print(supabaseUrl);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  print(supabaseUrl);

  runApp(const HanipChungjuApp());
}

class HanipChungjuApp extends StatelessWidget {
  const HanipChungjuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFF5EEDC);
    const beigeDark = Color(0xFFD8CAB8);
    const brownText = Color(0xFF5D4037);

    return MaterialApp(
      title: '한입충주',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: beige,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'NanumGothic',
        appBarTheme: AppBarTheme(
          backgroundColor: beige,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: brownText,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: brownText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: beigeDark,
            foregroundColor: brownText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: brownText),
          bodyMedium: TextStyle(color: Colors.grey.shade800, fontSize: 16),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignUpPage(),
        '/Start_page': (context) => StartPage(),
      },
    );
  }
}
