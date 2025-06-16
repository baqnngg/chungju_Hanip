import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chungju_project/screens/BookmarkPage.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/section_title.dart';
import 'MyPage.dart';
import 'RestaurantDetailPage.dart';
import 'my location_page.dart';

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
  Timer? _debounce;

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
          .from('restaurants_with_review_counts')
          .select('name, address, latitude, longitude, review_count');

      if (_searchKeyword.isNotEmpty) {
        query = query.ilike('name', '%$_searchKeyword%');
      }

      // Remove .execute() - just await the query directly
      final response = await query.range(offset, offset + limit - 1);

      final data = response as List<dynamic>;

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
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = value;
        offset = 0;
        hasMore = true;
        recommendedRestaurants.clear();
      });
      fetchRecommendedRestaurants();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchKeyword = '';
      offset = 0;
      hasMore = true;
      recommendedRestaurants.clear();
    });
    fetchRecommendedRestaurants();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Column(
        children: [
          AppBar(
            title: const Text('한입충주'),
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: '맛집 검색',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
                    : null,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _searchKeyword.isEmpty
                  ? [
                // 검색어 없을 때 내 근처 + 추천 + 리스트 보여주기
                SectionTitle(title: '내 근처의 맛집'),
                const SizedBox(height: 8),
                RestaurantCard(
                  name: '맛집 이름1',
                  address: '충주시 중앙로 123',
                  reviewCount: 0,
                  latitude: 36.991,  // 하드코딩된 위도/경도 추가
                  longitude: 127.925,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          name: '맛집 이름1',
                          address: '충주시 중앙로 123',
                          latitude: 36.991,
                          longitude: 127.925,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SectionTitle(title: '추천 맛집'),
                const SizedBox(height: 8),
                RestaurantCard(
                  name: '맛집 이름2',
                  address: '충주시 문화동 456',
                  reviewCount: 0,
                  latitude: 36.995,  // 하드코딩된 위도/경도 추가
                  longitude: 127.930,
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
                const SizedBox(height: 16),
                SectionTitle(title: '맛집 리스트'),
                const SizedBox(height: 8),
                ...recommendedRestaurants.map(
                      (restaurant) {
                    // 위도/경도 값 확인 및 디버깅
                    double? lat = restaurant['latitude']?.toDouble();
                    double? lng = restaurant['longitude']?.toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RestaurantCard(
                        name: restaurant['name'] ?? '이름 없음',
                        address: restaurant['address'] ?? '주소 없음',
                        reviewCount: restaurant['review_count'] ?? 0,
                        latitude: lat,  // double로 변환된 값 전달
                        longitude: lng, // double로 변환된 값 전달
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailPage(
                                name: restaurant['name'] ?? '이름 없음',
                                address: restaurant['address'] ?? '주소 없음',
                                latitude: lat ?? 36.991,  // null인 경우 기본값
                                longitude: lng ?? 127.925, // null인 경우 기본값
                              ),
                            ),
                          );

                          if (result == true) {
                            offset = 0;
                            hasMore = true;
                            recommendedRestaurants.clear();
                            fetchRecommendedRestaurants();
                          }
                        },
                      ),
                    );
                  },
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: fetchRecommendedRestaurants,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: const Text(
                          '더보기',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ]
                  : [
                // 검색어 있을 때는 검색 결과만 보여주기
                SectionTitle(title: '검색 결과'),
                const SizedBox(height: 8),
                ...recommendedRestaurants.map(
                      (restaurant) {
                    // 위도/경도 값 확인 및 디버깅
                    double? lat = restaurant['latitude']?.toDouble();
                    double? lng = restaurant['longitude']?.toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RestaurantCard(
                        name: restaurant['name'] ?? '이름 없음',
                        address: restaurant['address'] ?? '주소 없음',
                        reviewCount: restaurant['review_count'] ?? 0,
                        latitude: lat,  // double로 변환된 값 전달
                        longitude: lng, // double로 변환된 값 전달
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailPage(
                                name: restaurant['name'] ?? '이름 없음',
                                address: restaurant['address'] ?? '주소 없음',
                                latitude: lat ?? 36.991,  // null인 경우 기본값
                                longitude: lng ?? 127.925, // null인 경우 기본값
                              ),
                            ),
                          );

                          if (result == true) {
                            offset = 0;
                            hasMore = true;
                            recommendedRestaurants.clear();
                            fetchRecommendedRestaurants();
                          }
                        },
                      ),
                    );
                  },
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: fetchRecommendedRestaurants,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '더보기',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      NearbyRestaurantPage(),
      BookmarkPage(),
      MyPage(),

    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepOrangeAccent,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: '내 근처'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '북마크'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}