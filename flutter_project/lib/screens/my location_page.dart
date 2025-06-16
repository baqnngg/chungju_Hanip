import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'RestaurantDetailPage.dart';

class NearbyRestaurantPage extends StatefulWidget {
  const NearbyRestaurantPage({super.key});

  @override
  State<NearbyRestaurantPage> createState() => _NearbyRestaurantPageState();
}

class _NearbyRestaurantPageState extends State<NearbyRestaurantPage> {
  List<Map<String, dynamic>> nearbyRestaurants = [];
  bool isLoading = true;
  String errorMsg = '';

  // 고정 위치 좌표 (위치 권한 불필요)
  final double fixedLat = 36.94610;
  final double fixedLng = 127.9387;

  // 거리 선택 관련
  int selectedDistance = 1000; // 기본값 1km
  final List<int> distanceOptions = [500, 1000, 2000, 3000, 5000]; // 500m, 1km, 2km, 3km, 5km
  final List<String> distanceLabels = ['500m', '1km', '2km', '3km', '5km'];

  @override
  void initState() {
    super.initState();
    fetchNearbyRestaurants();
  }

  Future<void> fetchNearbyRestaurants() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });

    try {
      print('📍 고정 좌표 기준 검색: ($fixedLat, $fixedLng) - 반경: ${selectedDistance}m');

      final data = await Supabase.instance.client
          .from('restaurants_geocoded')
          .select('name, address, latitude, longitude');

      if (data == null || data.isEmpty) {
        setState(() {
          nearbyRestaurants = [];
          isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> filtered = [];

      for (var restaurant in data) {
        final latRaw = restaurant['latitude'];
        final lngRaw = restaurant['longitude'];

        if (latRaw != null && lngRaw != null) {
          final double lat = latRaw is int ? latRaw.toDouble() : latRaw;
          final double lng = lngRaw is int ? lngRaw.toDouble() : lngRaw;

          final distance = Geolocator.distanceBetween(
            fixedLat,
            fixedLng,
            lat,
            lng,
          );

          if (distance <= selectedDistance) {
            filtered.add({
              'name': restaurant['name'],
              'address': restaurant['address'],
              'latitude': lat,
              'longitude': lng,
              'distance': distance.toInt(),
            });
          }
        }
      }

      filtered.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        nearbyRestaurants = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = '데이터 불러오는 중 오류 발생!';
        isLoading = false;
      });
      print('🚨 맛집 데이터 오류: $e');
    }
  }

  void onDistanceChanged(int newDistance) {
    setState(() {
      selectedDistance = newDistance;
    });
    fetchNearbyRestaurants();
  }

  void openDetailPage(Map<String, dynamic> restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailPage(
          name: restaurant['name'],
          address: restaurant['address'],
          latitude: restaurant['latitude'],
          longitude: restaurant['longitude'],
          // 고정 위치 정보 전달
          myLatitude: fixedLat,
          myLongitude: fixedLng,
        ),
      ),
    ).then((value) {
      if (value == true) {
        fetchNearbyRestaurants();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 근처 맛집')),
      body: Column(
        children: [
          // 고정 위치 표시
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            child: Text(
              '고정 위치: ${fixedLat.toStringAsFixed(5)}, ${fixedLng.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // 거리 선택 버튼들
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '검색 반경 선택:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: distanceOptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      int distance = entry.value;
                      String label = distanceLabels[index];
                      bool isSelected = selectedDistance == distance;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () => onDistanceChanged(distance),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                            foregroundColor: isSelected ? Colors.white : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 결과 개수 표시
          if (!isLoading && errorMsg.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              width: double.infinity,
              child: Text(
                '반경 ${distanceLabels[distanceOptions.indexOf(selectedDistance)]} 내 맛집 ${nearbyRestaurants.length}개',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

          // 맛집 리스트
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg.isNotEmpty
                ? Center(child: Text(errorMsg))
                : nearbyRestaurants.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '반경 ${distanceLabels[distanceOptions.indexOf(selectedDistance)]} 내에\n맛집이 없어요!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '검색 반경을 늘려보세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: nearbyRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = nearbyRestaurants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.orange),
                    ),
                    title: Text(
                      restaurant['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      restaurant['address'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${restaurant['distance']}m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    onTap: () {
                      openDetailPage(restaurant);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}