import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geomeet/data/models/user_model.dart' as app_user;
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../../../services/firebase/database/firebase_database_service.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final _auth = FirebaseAuth.instance;
  final _dbService = FirebaseDatabaseService();
  final _isHandlingRequest = <String, bool>{};

  Future<void> _acceptRequest(String notificationId, String fromUid) async {
    if (_isHandlingRequest[notificationId] == true) return;
    _isHandlingRequest[notificationId] = true;
    setState(() {});

    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      await _dbService.createUserFriendship(currentUid, fromUid);

     
      await Future.wait([
        _dbService.deleteNotification(notificationId),
        _dbService.removeFriendRequest(fromUid, currentUid),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande acceptée - Vous êtes maintenant amis"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isHandlingRequest.remove(notificationId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _rejectRequest(String notificationId, String fromUid) async {
    if (_isHandlingRequest[notificationId] == true) return;
    _isHandlingRequest[notificationId] = true;
    setState(() {});

    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      await Future.wait([
        _dbService.deleteNotification(notificationId),
        _dbService.removeFriendRequest(fromUid, currentUid),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande refusée"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isHandlingRequest.remove(notificationId);
      if (mounted) setState(() {});
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final notifId = notif['id'];
    final fromUid = notif['from'];
    final isHandling = _isHandlingRequest[notifId] == true;

    return FutureBuilder<app_user.User?>(
      future: _dbService.getUser(fromUid),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();

        final sender = userSnap.data!;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.smallPadding),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.greenshede0,
                child: Text(
                  sender.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                notif['message'] ?? "${sender.username} vous a envoyé une demande d'ami",
                style: AppTextStyles.bodyText2,
              ),
              subtitle: Text(
                "Demande reçue",
                style: AppTextStyles.bodyText3.copyWith(color: Colors.grey),
              ),
              trailing: isHandling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _acceptRequest(notifId, fromUid),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectRequest(notifId, fromUid),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: AppTextStyles.headline2),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primarygreen),
      ),
      backgroundColor: AppColors.lightgreenshede,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _dbService.getNotificationsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement",
                style: AppTextStyles.bodyText2.copyWith(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppSizes.mediumPadding),
                  Text(
                    "Aucune notification",
                    style: AppTextStyles.bodyText2.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh the stream
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.mediumPadding),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationItem(notif);
              },
            ),
          );
        },
      ),
    );
  }
}