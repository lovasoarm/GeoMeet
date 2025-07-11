class User {
  final String id;
  final String username;
  final String email;
  final String? profilPicture;
  final bool isActive; 

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilPicture,
    this.isActive = false, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profilPicture': profilPicture,
      'isActive': isActive, 
    };
  }

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      profilPicture: map['profilPicture'],
      isActive: map['isActive'] ?? false, 
    );
  }
}
