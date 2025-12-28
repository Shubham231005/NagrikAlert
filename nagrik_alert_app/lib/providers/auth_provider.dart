import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isAdmin = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _isAdmin;
  bool get isCitizen => !_isAdmin;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.session != null) {
        await _loadUserProfile(state.session!.user.id);
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _isAdmin = false;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });

    // Check initial auth state
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _user = await _authService.getUserProfile(userId);
      _isAdmin = _user?.isAdmin ?? false;
    } catch (e) {
      // Use metadata as fallback
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = UserModel(
          id: currentUser.id,
          email: currentUser.email ?? '',
          name: currentUser.userMetadata?['name'],
          role: currentUser.userMetadata?['role'] ?? 'citizen',
          createdAt: DateTime.now(),
        );
        _isAdmin = _user?.isAdmin ?? false;
      }
    }
  }

  // Citizen Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: 'citizen',
        phone: phone,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Admin Sign Up
  Future<bool> adminSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Sign up with admin role
      final response = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: 'admin',
      );

      if (response.user == null) {
        throw Exception('Failed to create account');
      }

      // Sign out immediately so they can login via Admin Login
      await _authService.signOut();
      
      _user = null;
      _isAdmin = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Citizen Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.error;
      _errorMessage = 'Login failed';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Admin Sign In
  Future<bool> adminSignIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.adminSignIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        if (!_isAdmin) {
          await signOut();
          _status = AuthStatus.error;
          _errorMessage = 'Access denied. Admin privileges required.';
          notifyListeners();
          return false;
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.error;
      _errorMessage = 'Login failed';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _isAdmin = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({String? name}) async {
    try {
      if (name != null && _user != null) {
        _user = UserModel(
          id: _user!.id,
          email: _user!.email,
          name: name,
          role: _user!.role,
          createdAt: _user!.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Parse error messages
  String _parseError(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('email already registered') || message.contains('already been registered')) {
      return 'This email is already registered';
    } else if (message.contains('email_not_confirmed') || message.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox for a confirmation link, or disable email confirmation in Supabase settings.';
    } else if (message.contains('password')) {
      return 'Password must be at least 6 characters';
    } else if (message.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (message.contains('admin')) {
      return 'Access denied. Admin privileges required.';
    }
    
    return error.toString().replaceAll('Exception: ', '').replaceAll('AuthApiException(message: ', '').replaceAll(')', '');
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
