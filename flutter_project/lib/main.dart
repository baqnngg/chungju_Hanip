import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(HanipChungjuApp());

class HanipChungjuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFF5EEDC);      // 메인 베이지
    const beigeDark = Color(0xFFD8CAB8);  // 어두운 베이지
    const brownText = Color(0xFF5D4037);  // 진한 갈색

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
      home: SplashScreen(),
    );
  }
}
