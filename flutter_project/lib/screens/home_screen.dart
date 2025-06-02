import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chungju_project/screens/BookmarkPage.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/section_title.dart';
import 'MyPage.dart';
import 'RestaurantDetailPage.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> recommendedRestaurants = [];
  bool isLoading = false;
  bool hasMore = true;
  int limit = 10;
  int offset = 0;

  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    fetchRecommendedRestaurants();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchRecommendedRestaurants() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      var query = Supabase.instance.client
          .from('restaurants_geocoded')
          .select('name, address, latitude, longitude');

      if (_searchKeyword.isNotEmpty) {
        query = query.ilike('name', '%$_searchKeyword%');
      }

      final response = await query.range(offset, offset + limit - 1).execute();

      final data = response.data as List<dynamic>;

      if (data.length < limit) {
        hasMore = false;
      }

      setState(() {
        if (offset == 0) {
          recommendedRestaurants = data.cast<Map<String, dynamic>>();
        } else {
          recommendedRestaurants.addAll(data.cast<Map<String, dynamic>>());
        }
        offset += limit;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchKeyword = value;
    offset = 0;
    hasMore = true;
    recommendedRestaurants.clear();
    fetchRecommendedRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Column(
        children: [
          AppBar(
            title: const Text('한입충주'),
            automaticallyImplyLeading: false,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '맛집 검색',
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const SectionTitle(title: '내 근처의 맛집'),
                RestaurantCard(
                  name: '맛집 이름1',
                  address: '충주시 중앙로 123',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          name: '맛집 이름1',
                          address: '충주시 중앙로 123',
                          latitude: 36.991, // 실제 좌표 넣기
                          longitude: 127.925,
                        ),
                      ),
                    );
                  },
                ),
                const SectionTitle(title: '추천 맛집'),
                RestaurantCard(
                  name: '맛집 이름2',
                  address: '충주시 문화동 456',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          name: '맛집 이름2',
                          address: '충주시 문화동 456',
                          latitude: 36.995,
                          longitude: 127.930,
                        ),
                      ),
                    );
                  },
                ),
                const SectionTitle(title: '맛집 리스트'),
                ...recommendedRestaurants.map((restaurant) => RestaurantCard(
                  name: restaurant['name'] ?? '이름 없음',
                  address: restaurant['address'] ?? '주소 없음',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          name: restaurant['name'] ?? '이름 없음',
                          address: restaurant['address'] ?? '주소 없음',
                          latitude: restaurant['latitude'] ?? 0.0,
                          longitude: restaurant['longitude'] ?? 0.0,
                        ),
                      ),
                    );
                  },
                )),
                if (hasMore)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: fetchRecommendedRestaurants,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('더보기'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      BookmarkPage(),
      MyPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '북마크'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}
