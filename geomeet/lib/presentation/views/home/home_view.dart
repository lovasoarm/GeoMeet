import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:geomeet/presentation/views/auth/auth_viewmodel.dart';
import 'package:geomeet/app/routes.dart';
import 'package:geomeet/data/models/user_model.dart';
import 'package:geomeet/data/models/location_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../tracking/location_view.dart';
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

  @override
  void initState() {
    super.initState();
    _dbService.setUserActive(true);
    _updateUserPosition(); // Enregistre la position à l’ouverture
  }

  @override
  void dispose() {
    _dbService.setUserActive(false);
    super.dispose();
  }

  Future<void> _updateUserPosition() async {
    try {
      final hasPermission = await LocationService.checkLocationPermission();
      final isEnabled = await LocationService.checkLocationEnabled();
      if (!hasPermission || !isEnabled) return;

      // Appel statique de getCurrentPosition
      final position = await LocationService.getCurrentPosition();

      final currentUser = _dbService.currentUser;
      if (currentUser == null) return;

      // Crée un LocationModel avec la position actuelle
      final location = LocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        userId: currentUser.uid,
      );

      // Met à jour la position dans ta base Firebase
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: AppColors.primarygreen)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.setUserActive(false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.authview);
      }
    }
  }

  void _goToNotifications() => Navigator.pushNamed(context, AppRoutes.notification);
  void _goToAddFriend() => Navigator.pushNamed(context, AppRoutes.addFriend);

  Widget _buildFriendItem(User friend) {
    final isRemoving = _isRemovingFriend[friend.id] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.mediumMargin, vertical: AppSizes.smallMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.smallPadding),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.greenshede0,
                child: Text(friend.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
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
              Text(friend.email, style: AppTextStyles.bodyText3.copyWith(color: Colors.grey[600])),
            ],
          ),
          trailing: isRemoving
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.primarygreen),
                      tooltip: 'Supprimer cet ami',
                      onPressed: () => _confirmRemoveFriend(friend.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_on, color: AppColors.primarygreen),
                      tooltip: 'Localiser cet ami',
                      onPressed: () => _onTrackPressed(friend),
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
                    icon: const Icon(Icons.notifications, color: AppColors.primarygreen),
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            notifCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                prefixIcon: const Icon(Icons.search, color: AppColors.grayshade),
                filled: true,
                fillColor: AppColors.lightgreenshede1,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.mediumPadding),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                  return Center(child: Text('Erreur de chargement', style: AppTextStyles.bodyText2.copyWith(color: Colors.red)));
                }

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: AppSizes.mediumPadding),
                        Text("Aucun ami pour l’instant", style: AppTextStyles.bodyText2.copyWith(color: Colors.grey)),
                        const SizedBox(height: AppSizes.smallPadding),
                        Text("Appuyez sur le bouton + pour ajouter des amis", style: AppTextStyles.bodyText3.copyWith(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) => _buildFriendItem(friends[index]),
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

                      final activeFriend = friends.where((u) => u.isActive).toList();
                      if (activeFriend.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Aucun de vos amis n’est actuellement actif."),
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
