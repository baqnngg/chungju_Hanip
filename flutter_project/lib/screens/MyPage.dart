import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();

  bool _isNicknameFocused = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _nicknameFocusNode.addListener(() {
      setState(() {
        _isNicknameFocused = _nicknameFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // user_profiles 테이블에서 닉네임 불러오기
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select('nickname')
        .eq('id', user.id)
        .maybeSingle();

    final nickname = response != null ? response['nickname'] as String? : null;

    setState(() {
      _nicknameController.text = nickname ?? '';
    });
  }

  Future<bool> _isNicknameDuplicate(String nickname) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final response = await Supabase.instance.client
        .from('user_profiles')
        .select('nickname, id')
        .eq('nickname', nickname)
        .maybeSingle();

    // 닉네임이 존재하고, 그 닉네임이 현재 사용자 닉네임과 다를 때 중복으로 간주
    if (response != null && response['id'] != user.id) {
      return true;
    }
    return false;
  }

  Future<void> _updateNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    final isDuplicate = await _isNicknameDuplicate(nickname);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 사용 중인 닉네임입니다. 다른 닉네임을 입력해 주세요.')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 인증 메타데이터에 닉네임 업데이트
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'nickname': nickname}),
    );

    // user_profiles 테이블에 업서트 (id 기준)
    final response = await Supabase.instance.client.from('user_profiles').upsert({
      'id': user.id,
      'nickname': nickname,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('닉네임이 저장되었습니다.')),
    );

    _nicknameFocusNode.unfocus();
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('고객센터 이메일'),
        content: const Text('bbqdnrmas@gmail.com\n\n이메일 앱을 통해 문의해 주세요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 닉네임 입력 필드
            TextField(
              controller: _nicknameController,
              focusNode: _nicknameFocusNode,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _isNicknameFocused ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _updateNickname,
              child: const Text('닉네임 수정'),
            ),
            const Divider(height: 40),
            ListTile(
              title: const Text('계정'),
              subtitle: Text(user?.email ?? '이메일 없음'),
            ),
            ListTile(
              title: const Text('알림'),
              onTap: () {
                // 알림 설정 이동
              },
            ),
            ListTile(
              title: const Text('고객센터'),
              onTap: _showEmailDialog,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('로그아웃', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade900,
            fixedSize: const Size(120, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
