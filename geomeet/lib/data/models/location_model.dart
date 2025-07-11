class LocationModel {
  final String id; 
  final double latitude;
  final double longitude;
  final DateTime timestamp; 
  final String userId;

  LocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
}
