import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantCard extends StatefulWidget {
  final String name;
  final String address;
  final int reviewCount;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onTap;

  const RestaurantCard({
    required this.name,
    required this.address,
    required this.reviewCount,
    this.latitude,
    this.longitude,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool isBookmarked = false;
  bool isLoading = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('bookmarks')
          .select()
          .eq('user_id', user.id)
          .eq('restaurant_name', widget.name)
          .maybeSingle();
      if (mounted) {
        setState(() {
          isBookmarked = response != null;
        });
      }
    } catch (e) {
      print('북마크 상태 확인 오류: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isBookmarked) {
        // 북마크 제거
        await supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('restaurant_name', widget.name);

        if (mounted) {
          setState(() {
            isBookmarked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('북마크에서 제거되었습니다.')),
          );
        }
      } else {
        // 북마크 추가
        await supabase.from('bookmarks').insert({
          'user_id': user.id,
          'restaurant_name': widget.name,
          'restaurant_address': widget.address,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
        });
        if (mounted) {
          setState(() {
            isBookmarked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('북마크에 추가되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 왼쪽 텍스트 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.address),
                      const SizedBox(height: 8),
                      Text(
                        '리뷰 수: ${widget.reviewCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // 오른쪽 북마크 버튼
                isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.favorite : Icons.favorite_border,
                    color: isBookmarked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}