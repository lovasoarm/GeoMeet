// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/text_styles.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendPage> {
  final _searchController = TextEditingController();
  final db = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? _user;
  bool _loading = false;
  bool _notFound = false;
  bool _isAdding = false;
  bool _alreadyFriends = false;
  bool _requestPending = false;

  Future<void> _searchUser() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _user = null;
      _notFound = false;
      _alreadyFriends = false;
      _requestPending = false;
    });

    try {
      final snapshot = await db
          .child('users')
          .orderByChild('username')
          .equalTo(username)
          .once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.isNotEmpty) {
        final entry = data.entries.first;
        final v = Map<String, dynamic>.from(entry.value as Map);
        final currentUser = FirebaseAuth.instance.currentUser;

        if (entry.key == currentUser?.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Vous ne pouvez pas vous ajouter vous-même.")),
          );
          return;
        }

        final isFriend = await _checkFriendship(currentUser?.uid, entry.key);

        final hasPendingRequest =
            await _checkPendingRequest(currentUser?.uid, entry.key);

        setState(() {
          _user = {
            'key': entry.key,
            'username': v['username'],
            'isActive': v['isActive'] ?? false,
          };
          _alreadyFriends = isFriend;
          _requestPending = hasPendingRequest;
        });
      } else {
        setState(() {
          _notFound = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool> _checkFriendship(String? currentUid, String? targetUid) async {
    if (currentUid == null || targetUid == null) return false;
    final snapshot = await db.child('friends/$currentUid/$targetUid').get();
    return snapshot.exists;
  }

  Future<bool> _checkPendingRequest(
      String? currentUid, String? targetUid) async {
    if (currentUid == null || targetUid == null) return false;
    final snapshot =
        await db.child('friendRequests/$currentUid/$targetUid').get();
    return snapshot.exists;
  }

  Future<void> _sendFriendRequest() async {
    if (_user == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    if (_isAdding || _alreadyFriends || _requestPending) return;
    setState(() => _isAdding = true);

    try {
      final currentUid = currentUser.uid;
      final targetUid = _user!['key'];

      final requestId = db.child('notifications').push().key;
      await db.child('notifications/$requestId').set({
        'id': requestId,
        'from': currentUid,
        'to': targetUid,
        'type': 'friend_request',
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
        'message': '${_user!['username']} vous a envoyé une demande d\'ami',
      });

      await db.child('friendRequests/$currentUid/$targetUid').set(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande envoyée à ${_user!['username']}')),
      );

      setState(() {
        _requestPending = true;
        _isAdding = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un ami", style: AppTextStyles.headline2),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primarygreen),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.mediumPadding),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Nom d'utilisateur",
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.grayshade),
                filled: true,
                fillColor: AppColors.lightgreenshede1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loading ? null : _searchUser(),
            ),
            const SizedBox(height: AppSizes.mediumPadding),
            ElevatedButton(
              onPressed: (_loading || _isAdding) ? null : _searchUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarygreen,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Rechercher"),
            ),
            const SizedBox(height: AppSizes.largeMargin),
            if (_notFound)
              Text("Utilisateur non trouvé", style: AppTextStyles.bodyText3),
            if (_user != null)
              Card(
                margin:
                    const EdgeInsets.symmetric(vertical: AppSizes.mediumMargin),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.smallPadding),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(_user!['username'],
                            style: AppTextStyles.bodyText2),
                        subtitle: Text(
                          _user!['isActive'] ? "En ligne" : "Hors ligne",
                          style: AppTextStyles.bodyText3.copyWith(
                            color:
                                _user!['isActive'] ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      if (_alreadyFriends)
                        Text(
                          "Déjà ami",
                          style: AppTextStyles.bodyText3
                              .copyWith(color: Colors.green),
                        ),
                      if (_requestPending)
                        Text(
                          "Demande en attente",
                          style: AppTextStyles.bodyText3
                              .copyWith(color: Colors.orange),
                        ),
                      const SizedBox(height: AppSizes.smallPadding),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            _alreadyFriends
                                ? Icons.check_circle
                                : Icons.person_add,
                            size: AppSizes.smallIconSize,
                          ),
                          label: _isAdding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_alreadyFriends
                                  ? "Déjà ami"
                                  : _requestPending
                                      ? "Demande envoyée"
                                      : "Envoyer demande"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _alreadyFriends
                                ? Colors.green
                                : _requestPending
                                    ? Colors.orange
                                    : AppColors.colorAcent,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.mediumPadding),
                          ),
                          onPressed: _alreadyFriends || _requestPending
                              ? null
                              : _sendFriendRequest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
