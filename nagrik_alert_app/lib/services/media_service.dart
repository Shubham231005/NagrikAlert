import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  static const String _bucketName = 'incident-media';

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    return image != null ? File(image.path) : null;
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    return image != null ? File(image.path) : null;
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    return video != null ? File(video.path) : null;
  }

  // Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    return video != null ? File(video.path) : null;
  }

  // Upload file to Supabase Storage
  Future<String?> uploadFile(File file, {required String type}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = '$type/$fileName';

      print('📤 Uploading file: $filePath');
      print('📁 Bucket: $_bucketName');
      print('📊 File size: ${await file.length()} bytes');

      final response = await _supabase.storage.from(_bucketName).upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      print('✅ Upload response: $response');

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      print('🔗 Public URL: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      print('❌ Storage Exception: ${e.message}');
      print('❌ Status Code: ${e.statusCode}');
      print('❌ Error: ${e.error}');
      return null;
    } catch (e) {
      print('❌ Error uploading file: $e');
      return null;
    }
  }

  // Upload image
  Future<String?> uploadImage(File file) async {
    return await uploadFile(file, type: 'images');
  }

  // Upload video
  Future<String?> uploadVideo(File file) async {
    return await uploadFile(file, type: 'videos');
  }

  // Upload multiple files
  Future<List<Map<String, String>>> uploadMultipleFiles(
    List<File> files,
    List<String> types, // 'image' or 'video'
  ) async {
    List<Map<String, String>> results = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final type = types[i];

      String? url;
      if (type == 'image') {
        url = await uploadImage(file);
      } else {
        url = await uploadVideo(file);
      }

      if (url != null) {
        results.add({
          'url': url,
          'type': type,
        });
      }
    }

    return results;
  }

  // Delete file from storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) return false;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from(_bucketName).remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Save media info to database
  Future<void> saveMediaToDatabase({
    required String incidentId,
    required String mediaUrl,
    required String mediaType,
  }) async {
    try {
      await _supabase.from('incident_media').insert({
        'incident_id': incidentId,
        'media_url': mediaUrl,
        'media_type': mediaType,
      });
      print('✅ Saved media to database: $mediaUrl');
    } catch (e) {
      print('❌ Error saving media to database: $e');
    }
  }

  // Fetch media for an incident
  Future<List<Map<String, dynamic>>> getMediaForIncident(String incidentId) async {
    try {
      final response = await _supabase
          .from('incident_media')
          .select()
          .eq('incident_id', incidentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching media: $e');
      return [];
    }
  }

  // Fetch media for multiple incidents
  Future<Map<String, List<Map<String, dynamic>>>> getMediaForIncidents(List<String> incidentIds) async {
    if (incidentIds.isEmpty) return {};
    
    try {
      final response = await _supabase
          .from('incident_media')
          .select()
          .inFilter('incident_id', incidentIds);
      
      Map<String, List<Map<String, dynamic>>> result = {};
      for (var media in response) {
        final incidentId = media['incident_id'] as String;
        if (!result.containsKey(incidentId)) {
          result[incidentId] = [];
        }
        result[incidentId]!.add(media);
      }
      return result;
    } catch (e) {
      print('Error fetching media: $e');
      return {};
    }
  }
}

