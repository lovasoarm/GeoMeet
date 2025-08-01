// ignore_for_file: depend_on_referenced_packages

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
  String _selectedTileUrl =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  String _selectedTileName = 'OpenStreetMap';
  bool _showTileSelector = false;

  // Beautiful tile providers
  final Map<String, Map<String, dynamic>> _tileProviders = {
    'OpenStreetMap': {
      'url': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      'subdomains': ['a', 'b', 'c'],
      'attribution': '© OpenStreetMap contributors',
    },
    'OpenStreetMap France': {
      'url': 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
      'subdomains': ['a', 'b', 'c'],
      'attribution': '© OpenStreetMap France contributors',
    },
    'CartoDB Voyager': {
      'url':
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      'subdomains': ['a', 'b', 'c', 'd'],
      'attribution': '© OpenStreetMap contributors © CARTO',
    },
    'Esri World Imagery': {
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
      'attribution':
          'Tiles © Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
    },
    'OpenTopoMap': {
      'url': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      'subdomains': ['a', 'b', 'c'],
      'attribution':
          'Map data: © OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)',
    },
  };

  @override
  void initState() {
    super.initState();

    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
    }

    // Utiliser OpenStreetMap par défaut (affiche bien les noms et routes)
    _selectedTileUrl = _tileProviders['OpenStreetMap']!['url'];
    _selectedTileName = 'OpenStreetMap';

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

  void _changeTileProvider(String providerName) {
    setState(() {
      _selectedTileUrl = _tileProviders[providerName]!['url'];
      _selectedTileName = providerName;
      _showTileSelector = false;
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
      appBar: AppBar(
        backgroundColor: AppColors.primarygreen,
        foregroundColor: Colors.white,
        title: const Text('Localisation en temps réel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers, color: Colors.white),
            onSelected: _changeTileProvider,
            itemBuilder: (context) => _tileProviders.keys
                .map((name) => PopupMenuItem(
                      value: name,
                      child: Row(
                        children: [
                          Icon(
                            _selectedTileName == name
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: AppColors.primarygreen,
                          ),
                          const SizedBox(width: 8),
                          Text(name),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude, _currentLocation!.longitude)
                  : const LatLng(0, 0),
              initialZoom: 18,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _selectedTileUrl,
                subdomains: List<String>.from(
                    _tileProviders[_selectedTileName]!['subdomains']),
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarygreen.withValues(alpha: 0.3),
                          border: Border.all(
                            color: AppColors.primarygreen,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                      _tileProviders[_selectedTileName]!['attribution']),
                ],
              ),
            ],
          ),
          // Carte d'information en bas à gauche
          if (_currentLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primarygreen.withValues(alpha: 0.1),
                        Colors.white
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: AppColors.primarygreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Position actuelle',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primarygreen,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                      Text(
                        'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarygreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mis à jour à ${_currentLocation!.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${_currentLocation!.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primarygreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Indicateur de style de carte en haut à droite
          Positioned(
            top: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  _selectedTileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primarygreen,
                      ),
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
              16,
            );
          }
        },
        backgroundColor: AppColors.primarygreen,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
