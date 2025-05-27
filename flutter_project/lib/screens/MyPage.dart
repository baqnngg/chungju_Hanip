import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'nickname': nickname}),
    );

    await Supabase.instance.client.from('user_profiles').upsert({
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

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bbqdnrmas@gmail.com',
      query: Uri.encodeFull('subject=한입충주 고객센터 문의&body=문의 내용을 작성해주세요.'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw '이메일 앱을 열 수 없습니다.';
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nicknameController,
                        focusNode: _nicknameFocusNode,
                        decoration: InputDecoration(
                          labelText: '닉네임',
                          border: const OutlineInputBorder(),
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
                        leading: const Icon(Icons.info),
                        title: const Text('앱 정보'),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: '한입충주',
                            applicationVersion: '1.0.0',
                            children: [const Text('충주의 맛집 정보를 담은 앱입니다.')],
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: const Text('고객센터 문의'),
                        onTap: _launchEmail,
                      ),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('로그아웃'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
