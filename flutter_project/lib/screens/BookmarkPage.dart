import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'RestaurantDetailPage.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookmarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('bookmarks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          bookmarks = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('북마크 로드 오류: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmark(int bookmarkId, String restaurantName) async {
    try {
      // 북마크 삭제
      await supabase.from('bookmarks').delete().eq('id', bookmarkId);

      // UI에서 즉시 제거
      setState(() {
        bookmarks.removeWhere((bookmark) => bookmark['id'] == bookmarkId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$restaurantName 북마크가 해제되었습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 해제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: user == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('로그인이 필요합니다.', style: TextStyle(fontSize: 18)),
          ],
        ),
      )
          : isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarks.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('북마크한 맛집이 없습니다.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('맛집을 찾아서 북마크해보세요!',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadBookmarks,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            final createdAt = DateTime.parse(bookmark['created_at']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailPage(
                        name: bookmark['restaurant_name'],
                        address: bookmark['restaurant_address'],
                        latitude: bookmark['latitude'] ?? 0.0,
                        longitude: bookmark['longitude'] ?? 0.0,
                      ),
                    ),
                  );

                  // 상세 페이지에서 돌아왔을 때 북마크 새로고침
                  if (result == true) {
                    _loadBookmarks();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookmark['restaurant_name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookmark['restaurant_address'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '북마크 날짜: ${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 북마크 버튼만 남김
                      IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () => _toggleBookmark(
                          bookmark['id'],
                          bookmark['restaurant_name'],
                        ),
                        tooltip: '북마크 해제',
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