import 'package:flutter/material.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 북마크 데이터 리스트
    final List<Map<String, String>> bookmarks = [
      {'title': '첫 번째 게시글', 'description': '이건 북마크된 첫 번째 게시글이에요.'},
      {'title': '두 번째 게시글', 'description': '두 번째 것도 저장했네요.'},
      {'title': '세 번째 게시글', 'description': '이건 테스트용으로 추가한 항목이에요.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final item = bookmarks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Text(item['description'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  // 삭제 동작 구현 예정
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
