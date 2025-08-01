class User {
  final String id;
  final String username;
  final String email;
  final String? profilPicture;
  final bool isActive;
  final bool isLocationShared;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilPicture,
    this.isActive = false,
    this.isLocationShared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profilPicture': profilPicture,
      'isActive': isActive,
      'isLocationShared': isLocationShared,
    };
  }

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      profilPicture: map['profilPicture'],
      isActive: map['isActive'] ?? false,
      isLocationShared: map['isLocationShared'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profilPicture,
    bool? isActive,
    bool? isLocationShared,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilPicture: profilPicture ?? this.profilPicture,
      isActive: isActive ?? this.isActive,
      isLocationShared: isLocationShared ?? this.isLocationShared,
    );
  }
}
