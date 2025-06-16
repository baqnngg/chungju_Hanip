import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? myLatitude;  // 선택적 매개변수로 변경
  final double? myLongitude; // 선택적 매개변수로 변경

  const RestaurantDetailPage({
    Key? key,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.myLatitude,  // 선택적으로 변경
    this.myLongitude, // 선택적으로 변경
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
  LatLng? _myLocation;  // null 가능하도록 변경
  int? _distance;       // null 가능하도록 변경
  String currentNickname = '익명';
  bool _hasLocationData = false; // 위치 데이터 유무 확인용

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.latitude, widget.longitude);

    // 위치 데이터가 있는지 확인
    if (widget.myLatitude != null && widget.myLongitude != null) {
      _myLocation = LatLng(widget.myLatitude!, widget.myLongitude!);
      _hasLocationData = true;

      // 거리 계산
      _distance = Geolocator.distanceBetween(
        widget.myLatitude!,
        widget.myLongitude!,
        widget.latitude,
        widget.longitude,
      ).round();
    }

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
    return false;
  }

  // 선의 중점 계산 (위치 데이터가 있을 때만)
  LatLng _getMidPoint(LatLng point1, LatLng point2) {
    return LatLng(
      (point1.latitude + point2.latitude) / 2,
      (point1.longitude + point2.longitude) / 2,
    );
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

                // 위치 정보가 있을 때만 거리 표시
                if (_hasLocationData && _distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '내 위치에서 ${_distance}m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      // 위치 데이터가 있으면 중점으로, 없으면 레스토랑 위치로 중심 설정
                      initialCenter: _hasLocationData && _myLocation != null
                          ? _getMidPoint(_myLocation!, _center)
                          : _center,
                      initialZoom: 16.0,
                      maxZoom: 20.0,
                      minZoom: 2.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.yourapp',
                      ),

                      // 위치 데이터가 있을 때만 선 그리기
                      if (_hasLocationData && _myLocation != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_myLocation!, _center],
                              strokeWidth: 3.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),

                      // 마커들
                      MarkerLayer(
                        markers: [
                          // 위치 데이터가 있을 때만 내 위치 마커 표시
                          if (_hasLocationData && _myLocation != null)
                            Marker(
                              point: _myLocation!,
                              width: 80,
                              height: 80,
                              child: const Column(
                                children: [
                                  Icon(Icons.my_location, color: Colors.blue, size: 35),
                                  Text('내 위치', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),

                          // 레스토랑 위치 마커 (항상 표시)
                          Marker(
                            point: _center,
                            width: 80,
                            height: 80,
                            child: const Column(
                              children: [
                                Icon(Icons.restaurant, color: Colors.red, size: 35),
                                Text('식당', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          // 위치 데이터가 있을 때만 거리 표시 마커
                          if (_hasLocationData && _myLocation != null && _distance != null)
                            Marker(
                              point: _getMidPoint(_myLocation!, _center),
                              width: 100,
                              height: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${_distance}m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
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