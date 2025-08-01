// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart';
import 'package:geomeet/data/models/location_model.dart';
import 'package:geomeet/data/models/user_model.dart' as app_user;
import 'package:collection/collection.dart';

class FirebaseDatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final _auth = firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<void> sendUserLocation(LocationModel location) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await _db.child('userLocations/${user.uid}/${location.id}').set({
      ...location.toMap(),
      'timestamp': ServerValue.timestamp,
    });

    await _db.child('users/${user.uid}').update({
      'lastLocation': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': ServerValue.timestamp,
      }
    });
  }

  Future<void> updateUserLocation(Position position) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _db.child('users/$uid').update({
      'lastLocation': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }
    });
  }

  Stream<List<LocationModel>> getUserLocations() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .child('userLocations/${user.uid}')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        return LocationModel.fromMap({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        });
      }).toList();
    });
  }

  Stream<LocationModel?> getLastUserLocation() {
    return getUserLocations().map((locations) => locations.lastOrNull);
  }

  Stream<List<LocationModel>> getUserLocationsForUser(String uid) {
    return _db
        .child('userLocations/$uid')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        return LocationModel.fromMap({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        });
      }).toList();
    });
  }

  Stream<LocationModel?> getRealtimeFriendLocation(String friendId) {
    return _db
        .child('userLocations/$friendId')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;

      final lastEntry = data.entries.last;
      return LocationModel.fromMap({
        'id': lastEntry.key,
        ...Map<String, dynamic>.from(lastEntry.value),
      });
    });
  }

  Stream<List<LocationModel>> getFriendLocationsHistory(String friendId) {
    return _db
        .child('userLocations/$friendId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        return [];
      }

      final locations = data.entries.map((entry) {
        return LocationModel.fromMap({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        });
      }).toList();
      
      locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return locations;
    });
  }

  Future<void> createUser(app_user.User user) async {
    await _db.child('users/${user.id}').set({
      ...user.toMap(),
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<app_user.User?> getUser(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    return snapshot.exists
        ? app_user.User.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map))
        : null;
  }

  Stream<app_user.User?> getUserStream(String uid) {
    return _db.child('users/$uid').onValue.map((event) {
      return event.snapshot.exists
          ? app_user.User.fromJson(
              Map<String, dynamic>.from(event.snapshot.value as Map))
          : null;
    });
  }

  Future<void> setUserActive(bool isActive) async {
    final user = currentUser;
    if (user != null) {
      await _db.child('users/${user.uid}').update({
        'isActive': isActive,
        'lastActive': ServerValue.timestamp,
      });
    }
  }

  Future<void> setLocationShared(bool isLocationShared) async {
    final user = currentUser;
    if (user != null) {
      await _db.child('users/${user.uid}').update({
        'isLocationShared': isLocationShared,
        'locationSharedAt': ServerValue.timestamp,
      });
    }
  }

  Stream<List<app_user.User>> getFriendsOfCurrentUser() {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db.child('friends/$uid').onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      final friends = await Future.wait(
        data.keys.map((friendId) async {
          final snap = await _db.child('users/$friendId').get();
          return snap.exists
              ? app_user.User.fromJson(
                  Map<String, dynamic>.from(snap.value as Map))
              : null;
        }),
      );

      return friends.whereType<app_user.User>().toList();
    });
  }

  Future<bool> checkFriendshipStatus(String otherUserId) async {
    final currentUid = currentUser?.uid;
    if (currentUid == null) return false;

    final snapshot = await _db.child('friends/$currentUid/$otherUserId').get();
    return snapshot.exists;
  }

  Future<void> removeFriendship(String userA, String userB) async {
    await Future.wait([
      _db.child('friends/$userA/$userB').remove(),
      _db.child('friends/$userB/$userA').remove(),
    ]);
  }

  Future<void> sendFriendRequest(String receiverUid) async {
    final sender = currentUser;
    if (sender == null) throw Exception("Utilisateur non connecté");

    if (await checkFriendshipStatus(receiverUid)) {
      throw Exception("Vous êtes déjà ami avec cet utilisateur");
    }

    final existingRequest =
        await _db.child('friendRequests/${sender.uid}/$receiverUid').get();
    if (existingRequest.exists) {
      throw Exception("Demande déjà envoyée");
    }

    final requestId = _db.child('notifications').push().key;
    final senderUser = await getUser(sender.uid);

    await Future.wait([
      _db.child('notifications/$requestId').set({
        'id': requestId,
        'from': sender.uid,
        'to': receiverUid,
        'from_to': '${sender.uid}_$receiverUid',
        'type': 'friend_request',
        'message':
            '${senderUser?.username ?? "Quelqu’un"} veut vous ajouter en ami',
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
      }),
      _db.child('friendRequests/${sender.uid}/$receiverUid').set(true),
    ]);
  }

  Future<void> removeFriendRequest(String senderUid, String receiverUid) async {
    await _db.child('friendRequests/$senderUid/$receiverUid').remove();
  }

  Future<void> acceptFriendRequest(String senderUid) async {
    final receiverUid = currentUser?.uid;
    if (receiverUid == null) return;

    await createUserFriendship(senderUid, receiverUid);
  }

  Stream<List<Map<String, dynamic>>> getNotificationsForCurrentUser() {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db
        .child('notifications')
        .orderByChild('to')
        .equalTo(uid)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        return {
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.child('notifications/$notificationId').remove();
  }

  Future<void> createUserFriendship(String userA, String userB) async {
    final alreadyFriends = await checkFriendshipStatus(userB);
    if (alreadyFriends) return;

    await Future.wait([
      _db.child('friends/$userA/$userB').set(true),
      _db.child('friends/$userB/$userA').set(true),
      removeFriendRequest(userA, userB),
      removeFriendRequest(userB, userA),
      _deleteFriendRequestNotification('${userA}_$userB'),
      _deleteFriendRequestNotification('${userB}_$userA'),
    ]);
  }

  Future<void> _deleteFriendRequestNotification(String fromTo) async {
    final snapshot = await _db
        .child('notifications')
        .orderByChild('from_to')
        .equalTo(fromTo)
        .once();

    final data = snapshot.snapshot.value as Map?;
    if (data == null) return;

    for (final key in data.keys) {
      await _db.child('notifications/$key').remove();
    }
  }

  Future<void> cleanupUserData() async {
    final user = currentUser;
    if (user == null) return;

    await Future.wait([
      _db.child('userLocations/${user.uid}').remove(),
      _db.child('friends/${user.uid}').remove(),
      _db.child('friendRequests/${user.uid}').remove(),
    ]);
  }
}
