import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(HanipChungjuApp());

class HanipChungjuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한입충주',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 색상 팔레트 강화 - primarySwatch 대신 색상 세부 조정
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange, // 진한 주황으로 포인트
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50], // 너무 하얀색보다 부드럽게
        fontFamily: 'NanumGothic', // 한국어 지원 좋은 폰트로 변경 (pubspec.yaml에 추가 필요)
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.deepOrange.shade700),
          bodyMedium: TextStyle(color: Colors.grey[800], fontSize: 16),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}
