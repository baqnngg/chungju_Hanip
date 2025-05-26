import 'package:flutter/material.dart';

class RestaurantCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text('맛집 이름', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('간단한 설명 또는 위치'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            Text('4.5'),
          ],
        ),
        onTap: () {
          // TODO: 맛집 상세 페이지로 이동
        },
      ),
    );
  }
}
