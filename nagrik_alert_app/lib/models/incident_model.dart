class IncidentModel {
  final String id;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final int severity;
  final String status;
  final String? reporterId;
  final DateTime timestamp;
  final double? distanceMeters;
  final List<String> mediaUrls;
  final List<String> mediaTypes;

  IncidentModel({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    this.reporterId,
    required this.timestamp,
    this.distanceMeters,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    // Handle media URLs - could be null or List
    List<String> urls = [];
    if (json['media_urls'] != null) {
      if (json['media_urls'] is List) {
        urls = List<String>.from(json['media_urls'].map((e) => e?.toString() ?? ''));
      }
    }
    
    // Handle media types - could be null or List
    List<String> types = [];
    if (json['media_types'] != null) {
      if (json['media_types'] is List) {
        types = List<String>.from(json['media_types'].map((e) => e?.toString() ?? ''));
      }
    }

    return IncidentModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Other',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 1,
      status: json['status']?.toString() ?? 'Unverified',
      reporterId: json['reporter_id']?.toString(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      distanceMeters: json['distance_meters']?.toDouble(),
      mediaUrls: urls,
      mediaTypes: types,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'reporter_id': reporterId ?? 'anon',
      'media_urls': mediaUrls,
      'media_types': mediaTypes,
    };
  }

  // Check if has media
  bool get hasMedia => mediaUrls.isNotEmpty;
  
  // Get images only
  List<String> get images {
    List<String> result = [];
    for (int i = 0; i < mediaUrls.length; i++) {
      if (i < mediaTypes.length && mediaTypes[i] == 'image') {
        result.add(mediaUrls[i]);
      }
    }
    return result;
  }
  
  // Get videos only
  List<String> get videos {
    List<String> result = [];
    for (int i = 0; i < mediaUrls.length; i++) {
      if (i < mediaTypes.length && mediaTypes[i] == 'video') {
        result.add(mediaUrls[i]);
      }
    }
    return result;
  }

  // Helper getters
  bool get isVerified => status == 'Verified';
  bool get isResolved => status == 'Resolved';
  bool get isUnverified => status == 'Unverified';
  
  String get severityLabel {
    switch (severity) {
      case 1: return 'Low';
      case 2: return 'Minor';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Critical';
      default: return 'Unknown';
    }
  }
  
  int get severityColor {
    switch (severity) {
      case 1: return 0xFF4CAF50;
      case 2: return 0xFF8BC34A;
      case 3: return 0xFFFFC107;
      case 4: return 0xFFFF9800;
      case 5: return 0xFFF44336;
      default: return 0xFF9E9E9E;
    }
  }
  
  int get statusColor {
    switch (status) {
      case 'Verified': return 0xFF4CAF50;
      case 'Resolved': return 0xFF2196F3;
      case 'Rejected': return 0xFF9E9E9E;
      default: return 0xFFFFC107;
    }
  }
  
  String get typeEmoji {
    switch (type) {
      case 'Fire': return '🔥';
      case 'Accident': return '🚗';
      case 'Medical': return '🏥';
      case 'Infrastructure': return '🏗️';
      case 'Theft': return '🔒';
      case 'Natural Disaster': return '🌊';
      default: return '⚠️';
    }
  }
}
