import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up with Email & Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'citizen',
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'phone': phone,
        },
      );

      // Create user profile in database
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
          role: role,
          phone: phone,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Email & Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Admin Sign In
  Future<AuthResponse> adminSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verify admin role
      if (response.user != null) {
        final profile = await getUserProfile(response.user!.id);
        if (profile == null || profile.role != 'admin') {
          await signOut();
          throw Exception('Access denied. Admin privileges required.');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Create user profile in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Profile might already exist from trigger, try update instead
      try {
        await _supabase.from('profiles').update({
          'name': name,
          'role': role,
          'phone': phone,
        }).eq('id', userId);
      } catch (_) {
        // Ignore profile errors - user is created
      }
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      // If profile doesn't exist, create from auth metadata
      if (currentUser != null) {
        final metadata = currentUser!.userMetadata;
        return UserModel(
          id: currentUser!.id,
          email: currentUser!.email ?? '',
          name: metadata?['name'],
          role: metadata?['role'] ?? 'citizen',
          phone: metadata?['phone'],
          createdAt: DateTime.now(),
        );
      }
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}
