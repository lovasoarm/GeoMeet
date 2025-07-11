import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geomeet/data/models/location_model.dart';
import 'package:geomeet/services/firebase/database/firebase_database_service.dart';
import '../../../core/constants/colors.dart';

class MapView extends StatefulWidget {
  final String friendId;
  final LocationModel? initialLocation;

  const MapView({
    super.key,
    required this.friendId,
    this.initialLocation,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  StreamSubscription<LocationModel?>? _locationSubscription;
  LocationModel? _currentLocation;

  @override
  void initState() {
    super.initState();

    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
    }

    _startRealtimeTracking();
  }

  void _startRealtimeTracking() {
    _locationSubscription = FirebaseDatabaseService()
        .getRealtimeFriendLocation(widget.friendId)
        .listen((location) {
      if (location != null && mounted) {
        setState(() => _currentLocation = location);
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation != null
                  ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                  : const LatLng(0, 0),
              initialZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mg.company.map',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dernière position',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'À ${_currentLocation!.timestamp.toLocal().hour}h${_currentLocation!.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(
              LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
              18,
            );
          }
        },
        backgroundColor: AppColors.primarygreen,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
