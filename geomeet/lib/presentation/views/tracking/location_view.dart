import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:geomeet/presentation/views/tracking/map_view.dart';
import 'package:geomeet/services/geolocalisation/location_service.dart';
import 'package:geomeet/services/firebase/database/firebase_database_service.dart';
import 'package:geomeet/data/models/location_model.dart';
import 'package:geomeet/data/models/user_model.dart';
import '../../../core/constants/colors.dart';

class LocationTrackingView extends StatefulWidget {
  final User friend;

  const LocationTrackingView({super.key, required this.friend});

  @override
  State<LocationTrackingView> createState() => _LocationTrackingViewState();
}

class _LocationTrackingViewState extends State<LocationTrackingView> {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<LocationModel?>? _realtimeLocationSubscription;
  bool _isTracking = false;
  bool _isLoading = true;
  String? _error;
  LocationModel? _currentLocation;

  bool get isSelf {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.friend.id;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _realtimeLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (isSelf) {
      final permissionGranted = await LocationService.checkLocationPermission();
      final serviceEnabled = await LocationService.checkLocationEnabled();
      if (!permissionGranted) {
        setState(() {
          _error = "Permission de localisation refusée.";
          _isLoading = false;
        });
        return;
      }
      if (!serviceEnabled) {
        setState(() {
          _error = "Services de localisation désactivés.";
          _isLoading = false;
        });
        return;
      }

      _positionSubscription = LocationService.getPositionUpdates().listen(
        (position) async {
          await _handleNewPosition(position);
        },
        onError: (e) {
          setState(() => _error = e.toString());
        },
      );

      setState(() {
        _isTracking = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    _realtimeLocationSubscription = Provider.of<FirebaseDatabaseService>(
      context,
      listen: false,
    ).getRealtimeFriendLocation(widget.friend.id).listen((location) {
      if (location != null && mounted) {
        setState(() => _currentLocation = location);
      }
    });
  }

  Future<void> _handleNewPosition(Position position) async {
    try {
      final newLocation = LocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        userId: widget.friend.id,
      );

      await Provider.of<FirebaseDatabaseService>(context, listen: false)
          .sendUserLocation(newLocation);

      if (mounted) {
        setState(() => _currentLocation = newLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi en temps réel de ${widget.friend.username}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primarygreen),
        actions: [
          if (isSelf)
            IconButton(
              icon: Icon(
                _isTracking ? Icons.location_on : Icons.location_off,
                color: AppColors.primarygreen,
              ),
              onPressed: () {
                if (_isTracking) {
                  _positionSubscription?.pause();
                  setState(() => _isTracking = false);
                } else {
                  _positionSubscription?.resume();
                  setState(() => _isTracking = true);
                }
              },
            ),
        ],
      ),
      body: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        if (_currentLocation != null)
          Expanded(
            child: MapView(
              friendId: widget.friend.id,
              initialLocation: _currentLocation,
            ),
          ),
        if (_currentLocation != null) _buildLocationDetails(theme),
        Expanded(
          flex: 1,
          child: _buildLocationsHistory(theme),
        ),
      ],
    );
  }

  Widget _buildLocationDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0.3 as int),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position actuelle',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'À ${_currentLocation!.timestamp.toLocal().hour}h${_currentLocation!.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapView(
                    friendId: widget.friend.id,
                    initialLocation: _currentLocation,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarygreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Ouvrir carte",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsHistory(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Historique des positions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<List<LocationModel>>(
              stream: Provider.of<FirebaseDatabaseService>(
                context,
                listen: false,
              ).getFriendLocationsHistory(widget.friend.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur : ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final locations = snapshot.data!;
                if (locations.isEmpty) {
                  return const Center(child: Text("Aucune position enregistrée."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final loc = locations[locations.length - 1 - index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarygreen,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '${loc.timestamp.day}/${loc.timestamp.month} à ${loc.timestamp.hour}:${loc.timestamp.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.map,
                          color: AppColors.primarygreen,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapView(
                                friendId: widget.friend.id,
                                initialLocation: loc,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
