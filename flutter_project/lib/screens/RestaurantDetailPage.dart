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
  String currentNickname = '익명';

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.latitude, widget.longitude);
    _loadUserNickname();
    _loadReviews();
  }

  Future<void> _loadUserNickname() async {
    final user = supabase.auth.currentUser;

    if (user != null && user.userMetadata != null) {
      final metadata = Map<String, dynamic>.from(user.userMetadata!);
      setState(() {
        currentNickname = metadata['nickname']?.toString() ?? '익명';
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      // Remove .execute() - just await the query directly
      final data = await supabase
          .from('reviews')
          .select()
          .eq('restaurant_name', widget.name)
          .order('created_at', ascending: false);

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

    try {
      await supabase.from('reviews').insert({
        'restaurant_name': widget.name,
        'review_text': text,
        'user_name': currentNickname,
      });

      _reviewController.clear();
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 성공적으로 업로드되었습니다.')),
      );

      // 뒤로 가지 않고 현재 페이지 유지 (Navigator.pop 제거)
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 업로드 실패: $error')),
      );
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    try {
      await supabase.from('reviews').delete().eq('id', reviewId);
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 삭제되었습니다.')),
      );
      // 삭제 후에도 뒤로가기 시 알림 필요하면 여기에 Navigator.pop(context, true); 추가 가능
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 삭제 실패: $error')),
      );
    }
  }

  void _editReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _editController =
        TextEditingController(text: review['review_text']);

        return AlertDialog(
          title: const Text('리뷰 수정'),
          content: TextField(
            controller: _editController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase
                      .from('reviews')
                      .update({'review_text': _editController.text.trim()})
                      .eq('id', review['id']);
                  Navigator.of(context).pop();
                  await _loadReviews();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('리뷰가 수정되었습니다.')),
                  );
                  // 필요 시 Navigator.pop(context, true); 추가 가능
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('리뷰 수정 실패: $error')),
                  );
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, true);
    return false; // 기본 뒤로가기 막음
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                    style:
                    TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
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
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    final isMine =
                        review['user_name'] == currentNickname;
                    final formattedDate = review['created_at'] != null
                        ? DateTime.tryParse(review['created_at'])
                        : null;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      margin:
                      const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['user_name'] ?? '익명',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  formattedDate != null
                                      ? '${formattedDate.year}년 ${formattedDate.month}월 ${formattedDate.day}일'
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    review['review_text'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 14),
                                  ),
                                ),
                                if (isMine)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            size: 20),
                                        onPressed: () =>
                                            _editReview(review),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete,
                                            size: 20),
                                        onPressed: () => _deleteReview(
                                            review['id'] as int),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}