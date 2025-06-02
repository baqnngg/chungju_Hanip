import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  _RestaurantDetailPageState createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late final MapController _mapController;
  late LatLng _center;
  double _currentZoom = 17.0;
  final double _minZoom = 2.0;
  final double _maxZoom = 20.0;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.latitude, widget.longitude);
    _mapController = MapController();
  }

  void _zoomIn() {
    if (_currentZoom < _maxZoom) {
      _currentZoom += 1;
      _mapController.move(_center, _currentZoom);
      setState(() {});
    }
  }

  void _zoomOut() {
    if (_currentZoom > _minZoom) {
      _currentZoom -= 1;
      _mapController.move(_center, _currentZoom);
      setState(() {});
    }
  }

  void _goToLocation() {
    _mapController.move(_center, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(height: 20),
            const Text('주소',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(widget.address, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            /// 지도 영역 줄이기
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _currentZoom,
                      maxZoom: _maxZoom,
                      minZoom: _minZoom,
                      backgroundColor: Colors.grey[200]!,
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
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'zoom_in_btn',
                          mini: true,
                          child: const Icon(Icons.zoom_in),
                          onPressed: _zoomIn,
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'zoom_out_btn',
                          mini: true,
                          child: const Icon(Icons.zoom_out),
                          onPressed: _zoomOut,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 20),
                    child: FloatingActionButton(
                      heroTag: 'go_to_location_btn',
                      mini: true,
                      child: const Icon(Icons.my_location),
                      onPressed: _goToLocation,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}