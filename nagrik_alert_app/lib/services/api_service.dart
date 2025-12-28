import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/incident_model.dart';

class ApiService {
  final String _baseUrl = AppConstants.apiBaseUrl;

  // Headers with device ID for anti-spam
  Map<String, String> _headers(String deviceId) => {
    'Content-Type': 'application/json',
    'x-device-id': deviceId,
  };

  // Report a new incident
  Future<IncidentModel> reportIncident({
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    required int severity,
    required String reporterId,
    required String deviceId,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
  }) async {
    final body = {
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'reporter_id': reporterId,
    };

    // Add media if present
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['media_urls'] = mediaUrls;
    }
    if (mediaTypes != null && mediaTypes.isNotEmpty) {
      body['media_types'] = mediaTypes;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl${AppConstants.apiReportPath}'),
      headers: _headers(deviceId),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return IncidentModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403) {
      throw Exception('Device Banned - Contact support');
    } else if (response.statusCode == 409) {
      throw Exception('Duplicate Report - Similar incident already reported nearby');
    } else {
      throw Exception('Failed to report incident: ${response.body}');
    }
  }

  // Get all incidents
  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? incidentType,
    int? severityMin,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (incidentType != null) queryParams['incident_type'] = incidentType;
    if (severityMin != null) queryParams['severity_min'] = severityMin.toString();

    final uri = Uri.parse('$_baseUrl/api/v1/incidents').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => IncidentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch incidents: ${response.body}');
    }
  }

  // Get incident by ID
  Future<IncidentModel> getIncidentById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/incidents/$id'),
    );

    if (response.statusCode == 200) {
      return IncidentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Incident not found');
    }
  }

  // Get nearby incidents
  Future<List<IncidentModel>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/incidents/nearby/$latitude/$longitude?radius_meters=$radiusMeters'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> incidents = data['incidents'] ?? [];
      return incidents.map((json) => IncidentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch nearby incidents');
    }
  }

  // Update incident status (Admin only)
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    required String adminId,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/v1/incidents/$incidentId/status?new_status=$newStatus&admin_id=$adminId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status: ${response.body}');
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/stats'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch statistics');
    }
  }

  // Get audit trail
  Future<List<Map<String, dynamic>>> getAuditTrail(String incidentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/audit/$incidentId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['logs'] ?? []);
    } else {
      throw Exception('Failed to fetch audit trail');
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
