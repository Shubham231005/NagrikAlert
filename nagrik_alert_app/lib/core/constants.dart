class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://hacfpqidcyswbjqpnapa.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_BZxG8yDRS6262N8hTI1RuA_LRtPuZip';
  
  // Backend API Configuration (Hugging Face Spaces)
  static const String apiBaseUrl = 'https://shubham231005-nagrikalert.hf.space';
  static const String wsUrl = 'wss://shubham231005-nagrikalert.hf.space/ws/feed';
  
  // Correct API endpoint
  static const String apiReportPath = '/api/v1/report';
  
  // Incident Types
  static const List<String> incidentTypes = [
    'Fire',
    'Accident',
    'Medical',
    'Infrastructure',
    'Theft',
    'Natural Disaster',
    'Other',
  ];
  
  // Severity Levels
  static const Map<int, String> severityLevels = {
    1: 'Low',
    2: 'Minor',
    3: 'Moderate',
    4: 'High',
    5: 'Critical',
  };
  
  // Severity Colors
  static const Map<int, int> severityColors = {
    1: 0xFF4CAF50, // Green
    2: 0xFF8BC34A, // Light Green
    3: 0xFFFFC107, // Yellow
    4: 0xFFFF9800, // Orange
    5: 0xFFF44336, // Red
  };
}
