import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chungju_project/screens/BookmarkPage.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/section_title.dart';
import 'MyPage.dart';

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
    if (isLoading || !hasMore) {
      print('fetchRecommendedRestaurants 호출 무시됨 - isLoading: $isLoading, hasMore: $hasMore');
      return;
    }

    setState(() {
      isLoading = true;
    });
    print('fetchRecommendedRestaurants 시작, offset: $offset');

    try {
      final response = await Supabase.instance.client
          .from('restaurants')
          .select('name, address')  // name, address만 선택
          .range(offset, offset + limit - 1)
          .execute();

      final data = response.data as List<dynamic>;

      print('가져온 데이터 수: ${data.length}');

      if (data.length < limit) {
        hasMore = false;
        print('더 가져올 데이터 없음, hasMore: $hasMore');
      }

      setState(() {
        recommendedRestaurants.addAll(data.cast<Map<String, dynamic>>());
        offset += limit;
        isLoading = false;
      });

      print('추천 맛집 리스트 업데이트 완료, 현재 리스트 길이: ${recommendedRestaurants.length}, 다음 offset: $offset');
    } catch (e) {
      print('fetchRecommendedRestaurants 예외 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const SectionTitle(title: '내 근처의 맛집'),
                const RestaurantCard(
                  name: '맛집 이름1',
                  address: '충주시 중앙로 123',
                ),
                const RestaurantCard(
                  name: '맛집 이름2',
                  address: '충주시 문화동 456',
                ),
                const SectionTitle(title: '추천 맛집'),
                const RestaurantCard(
                  name: '맛집 이름2',
                  address: '충주시 문화동 456',
                ),
                const SectionTitle(title: '맛집 리스트'),
                ...recommendedRestaurants.map((restaurant) => RestaurantCard(
                  name: restaurant['name'] ?? '이름 없음',
                  address: restaurant['address'] ?? '주소 없음',
                )),
                if (hasMore)
                  TextButton(
                    onPressed: fetchRecommendedRestaurants,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('더보기'),
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
