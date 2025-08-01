import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geomeet/presentation/views/auth/auth_viewmodel.dart';
import 'package:geomeet/app/routes.dart';
import 'package:geomeet/data/models/user_model.dart';
import 'package:geomeet/data/models/location_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../tracking/location_view.dart';
import '../tracking/map_view.dart';
import '../../../services/firebase/database/firebase_database_service.dart';
import '../../../services/geolocalisation/location_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _dbService = FirebaseDatabaseService();
  final Map<String, bool> _isRemovingFriend = {};
  bool _isLocationShared = false;
  bool _isLoadingLocationToggle = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _dbService.setUserActive(true);
    _loadLocationSharingState();
    _updateUserPosition(); // Enregistre la position à l'ouverture
  }

  Future<void> _loadLocationSharingState() async {
    final currentUser = _dbService.currentUser;
    if (currentUser != null) {
      final userData = await _dbService.getUser(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _isLocationShared = userData.isLocationShared;
        });
        
        if (_isLocationShared) {
          _updateUserPosition(); // Enregistrement immédiat à la connexion
          _startLocationUpdates();
        }
      }
    }
  }

  @override
  void dispose() {
    _dbService.setUserActive(false);
    _stopLocationUpdates();
    super.dispose();
  }

  void _startLocationUpdates() {
    _stopLocationUpdates(); // Arrête le timer précédent s'il existe
    
    // Met à jour la position toutes les 30 secondes quand le partage est activé
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isLocationShared) {
        _updateUserPosition();
      } else {
        _stopLocationUpdates();
      }
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _updateUserPosition() async {
    try {
      final hasPermission = await LocationService.checkLocationPermission();
      final isEnabled = await LocationService.checkLocationEnabled();
      if (!hasPermission || !isEnabled) return;

      final position = await LocationService.getCurrentPosition();

      final currentUser = _dbService.currentUser;
      if (currentUser == null) return;

      final location = LocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        userId: currentUser.uid,
      );

      await _dbService.sendUserLocation(location);
    } catch (e) {
      debugPrint('Erreur de localisation : $e');
    }
  }

  void _onTrackPressed(User friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationTrackingView(friend: friend),
      ),
    );
  }

  void _onViewOnMapPressed(User friend) async {
    if (!mounted) return;
    
    try {
      final lastLocation = _dbService.getRealtimeFriendLocation(friend.id);
      
      await lastLocation.first.then((location) {
        if (!mounted) return;
        
        if (location != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapView(
                friendId: friend.id,
                initialLocation: location,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.username} n\'a pas de localisation disponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la récupération de la localisation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final currentUser = _dbService.currentUser;
    if (currentUser == null) return;

    setState(() => _isRemovingFriend[friendId] = true);

    try {
      await _dbService.removeFriendship(currentUser.uid, friendId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ami supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRemovingFriend.remove(friendId));
    }
  }

  Future<void> _confirmRemoveFriend(String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet ami ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: TextStyle(color: AppColors.primarygreen)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeFriend(friendId);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.setUserActive(false);
      // ignore: use_build_context_synchronously
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.authview);
      }
    }
  }

  void _goToNotifications() =>
      Navigator.pushNamed(context, AppRoutes.notification);
  void _goToAddFriend() => Navigator.pushNamed(context, AppRoutes.addFriend);

  Widget _buildFriendItem(User friend) {
    final isRemoving = _isRemovingFriend[friend.id] == true;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.mediumMargin, vertical: AppSizes.smallMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.smallPadding),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.greenshede0,
                child: Text(friend.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
              if (friend.isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friend.username, style: AppTextStyles.bodyText2),
              const SizedBox(height: 4),
              Text(friend.email,
                  style: AppTextStyles.bodyText3
                      .copyWith(color: Colors.grey[600])),
            ],
          ),
          trailing: isRemoving
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: AppColors.primarygreen),
                      tooltip: 'Supprimer cet ami',
                      onPressed: () => _confirmRemoveFriend(friend.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_on,
                          color: AppColors.primarygreen),
                      tooltip: 'Voir position actuelle sur la carte',
                      onPressed: () => _onViewOnMapPressed(friend),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightgreenshede,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('GeoMeet', style: AppTextStyles.headline2),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.getNotificationsForCurrentUser(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final notifCount = notifications.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications,
                        color: AppColors.primarygreen),
                    onPressed: _goToNotifications,
                  ),
                  if (notifCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            notifCount.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Déconnexion',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.mediumPadding),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Chercher quelqu’un",
                hintStyle: AppTextStyles.bodyText3,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.grayshade),
                filled: true,
                fillColor: AppColors.lightgreenshede1,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.mediumPadding),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSizes.mediumPadding,
              vertical: AppSizes.smallPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isLocationShared 
                          ? AppColors.primarygreen.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isLocationShared ? Icons.location_on : Icons.location_off,
                      color: _isLocationShared 
                          ? AppColors.primarygreen 
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partager ma localisation',
                          style: AppTextStyles.bodyText2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLocationShared
                              ? 'Vos amis peuvent voir votre position'
                              : 'Vos amis ne peuvent pas vous localiser',
                          style: AppTextStyles.bodyText3.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingLocationToggle)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarygreen),
                      ),
                    )
                  else
                    Switch(
                      value: _isLocationShared,
                      onChanged: (value) async {
                        setState(() => _isLoadingLocationToggle = true);
                        try {
                          await _dbService.setLocationShared(value);
                          if (mounted) {
                            setState(() {
                              _isLocationShared = value;
                            });
                            
                            // Démarrer ou arrêter les mises à jour automatiques
                            if (value) {
                              _updateUserPosition(); // Mise à jour immédiate
                              _startLocationUpdates(); // Démarrer les mises à jour périodiques
                            } else {
                              _stopLocationUpdates(); // Arrêter les mises à jour
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Partage de localisation activé - Position mise à jour automatiquement'
                                      : 'Partage de localisation désactivé',
                                ),
                                backgroundColor: value 
                                    ? AppColors.primarygreen 
                                    : Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoadingLocationToggle = false);
                          }
                        }
                      },
                      activeColor: AppColors.primarygreen,
                      activeTrackColor: AppColors.primarygreen.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[300],
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: _dbService.getFriendsOfCurrentUser(),
              builder: (context, snapshot) {
                final friends = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erreur de chargement',
                          style: AppTextStyles.bodyText2
                              .copyWith(color: Colors.red)));
                }

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: AppSizes.mediumPadding),
                        Text("Aucun ami pour l’instant",
                            style: AppTextStyles.bodyText2
                                .copyWith(color: Colors.grey)),
                        const SizedBox(height: AppSizes.smallPadding),
                        Text("Appuyez sur le bouton + pour ajouter des amis",
                            style: AppTextStyles.bodyText3
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) =>
                        _buildFriendItem(friends[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddFriend,
        backgroundColor: AppColors.greenshede0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: StreamBuilder<List<User>>(
            stream: _dbService.getFriendsOfCurrentUser(),
            builder: (context, snapshot) {
              final friends = snapshot.data ?? [];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    color: AppColors.primarygreen,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    color: AppColors.grayshade,
                    tooltip: 'Voir la position d’un ami',
                    onPressed: () {
                      if (friends.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vous n’avez pas encore d’amis."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final activeFriend =
                          friends.where((u) => u.isActive).toList();
                      if (activeFriend.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Aucun de vos amis n’est actuellement actif."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      _onTrackPressed(activeFriend.first);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
