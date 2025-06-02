import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const RestaurantDetailPage({
    Key? key,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final MapController _mapController = MapController();
  final TextEditingController _reviewController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = false;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.latitude, widget.longitude);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      final response = await supabase
          .from('reviews') // 리뷰 저장용 테이블명
          .select()
          .eq('restaurant_name', widget.name)
          .order('created_at', ascending: false)
          .execute();


      final data = response.data;
      if (data == null || !(data is List)) {
        throw '리뷰 데이터가 없습니다.';
      }

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 불러오기 실패: $error')),
      );
    } finally {
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) return;

    final user = supabase.auth.currentUser;
    final username = user?.email ?? 'Anonymous';

    try {
      final response = await supabase
          .from('reviews') // 리뷰 저장용 테이블명
          .insert({
        'restaurant_name': widget.name,
        'review_text': text,
        'user_name': username,
        // created_at은 DB에서 자동 생성 (timestamp default now())
      }).execute();

      _reviewController.clear();
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 성공적으로 업로드되었습니다.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 업로드 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.name,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Divider(height: 20),
              const Text('주소',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              Text(widget.address, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 17.0,
                    maxZoom: 20.0,
                    minZoom: 2.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.yourapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('리뷰 작성',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '리뷰를 작성하세요...',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitReview,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('리뷰 목록',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _loadingReviews
                  ? const Center(child: CircularProgressIndicator())
                  : _reviews.isEmpty
                  ? const Text('아직 리뷰가 없습니다.')
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return Card(
                    child: ListTile(
                      title: Text(review['user_name'] ?? '익명'),
                      subtitle: Text(review['review_text'] ?? ''),
                      trailing: Text(
                        review['created_at'] != null
                            ? review['created_at']
                            .toString()
                            .substring(0, 10)
                            : '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
