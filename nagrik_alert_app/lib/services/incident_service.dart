import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident_model.dart';

class IncidentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Report a new incident directly to Supabase
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
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final data = {
        'id': id,
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'status': 'Unverified',
        'reporter_id': reporterId,
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'media_urls': mediaUrls ?? [],
        'media_types': mediaTypes ?? [],
      };

      await _supabase.from('incidents').insert(data);
      
      print('✅ Incident saved to Supabase: $id');
      
      return IncidentModel(
        id: id,
        type: type,
        description: description,
        latitude: latitude,
        longitude: longitude,
        severity: severity,
        status: 'Unverified',
        reporterId: reporterId,
        timestamp: DateTime.now(),
        mediaUrls: mediaUrls ?? [],
        mediaTypes: mediaTypes ?? [],
      );
    } catch (e) {
      print('❌ Error saving incident: $e');
      throw Exception('Failed to save incident: $e');
    }
  }

  // Get all incidents from Supabase
  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? incidentType,
    int? severityMin,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('incidents').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (incidentType != null) {
        query = query.eq('type', incidentType);
      }
      if (severityMin != null) {
        query = query.gte('severity', severityMin);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => IncidentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching incidents: $e');
      return [];
    }
  }

  // Get incident by ID
  Future<IncidentModel?> getIncidentById(String id) async {
    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .eq('id', id)
          .single();
      
      return IncidentModel.fromJson(response);
    } catch (e) {
      print('Error fetching incident: $e');
      return null;
    }
  }

  // Update incident status
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
  }) async {
    try {
      await _supabase
          .from('incidents')
          .update({'status': newStatus})
          .eq('id', incidentId);
      return true;
    } catch (e) {
      print('Error updating incident: $e');
      return false;
    }
  }
}
