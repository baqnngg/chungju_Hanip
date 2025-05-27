import 'package:flutter/material.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/section_title.dart';
import 'MyPage.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 각 탭에 해당하는 위젯들
  final List<Widget> _pages = [
    HomeContent(),
    Center(child: Text('북마크')), // 추후 BookmarkPage로 대체
    MyPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('한입충주'),
          automaticallyImplyLeading: false,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '맛집 검색',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              SectionTitle(title: '내 근처의 맛집'),
              RestaurantCard(),
              RestaurantCard(),
              SectionTitle(title: '추천 맛집'),
              RestaurantCard(),
            ],
          ),
        ),
      ],
    );
  }
}
