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
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec avatar et nom
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primarygreen,
                            AppColors.greenshede0
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          sender.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender.username,
                            style: AppTextStyles.bodyText2.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "vous a envoyé une invitation",
                            style: AppTextStyles.bodyText3.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Boutons d'action
                if (isHandling)
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primarygreen),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Bouton refuser
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextButton(
                            onPressed: () => _rejectRequest(notifId, fromUid),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              "Refuser",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bouton accepter
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primarygreen,
                                AppColors.greenshede0
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primarygreen
                                    .withValues(alpha: 0.3),
                                spreadRadius: 0,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () => _acceptRequest(notifId, fromUid),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              "Accepter",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
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
