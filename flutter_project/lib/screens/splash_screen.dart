import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 여기서 초기화 작업 및 로그인 상태 체크
    await Future.delayed(Duration(seconds: 2));  // 예: 2초 로딩 화면

    final session = Supabase.instance.client.auth.currentSession;

    Navigator.pushReplacementNamed(context, '/Start_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로고나 앱 이름 넣기 좋음
            Icon(Icons.fastfood, size: 80, color: Colors.brown),
            SizedBox(height: 20),
            Text(
              '한입충주',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.brown),
          ],
        ),
      ),
    );
  }
}
