import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../database/database_service.dart';

class AuthService {
  static const String _sessionKey = 'user_session';
  static const String _rememberMeKey = 'remember_me';

  // Encrypt password using SHA-256
  static String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate inputs
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      if (password != confirmPassword) {
        return {'success': false, 'message': 'Passwords do not match'};
      }

      if (password.length < 6) {
        return {'success': false, 'message': 'Password must be at least 6 characters'};
      }

      if (!_isValidEmail(email)) {
        return {'success': false, 'message': 'Please enter a valid email'};
      }

      final db = DatabaseService.instance;

      // Check if username already exists
      final existingUser = await db.getUserByUsername(username);
      if (existingUser != null) {
        return {'success': false, 'message': 'Username already exists'};
      }

      // Check if email already exists
      final existingEmail = await db.getUserByEmail(email);
      if (existingEmail != null) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Create new user
      final hashedPassword = _encryptPassword(password);
      final user = User(
        username: username,
        email: email,
        passwordHash: hashedPassword,
        createdAt: DateTime.now(),
      );

      final userId = await db.insertUser(user);
      final newUser = user.copyWith(id: userId);

      return {
        'success': true,
        'message': 'Registration successful',
        'user': newUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      if (usernameOrEmail.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      final db = DatabaseService.instance;
      User? user;

      // Try to find user by username or email
      if (_isValidEmail(usernameOrEmail)) {
        user = await db.getUserByEmail(usernameOrEmail);
      } else {
        user = await db.getUserByUsername(usernameOrEmail);
      }

      if (user == null) {
        return {'success': false, 'message': 'User not found'};
      }

      // Verify password
      final hashedPassword = _encryptPassword(password);
      if (user.passwordHash != hashedPassword) {
        return {'success': false, 'message': 'Invalid password'};
      }

      // Save session
      await _saveSession(user, rememberMe);

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Save user session
  static Future<void> _saveSession(User user, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    
    final sessionData = {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'profile_image': user.profileImage,
      'created_at': user.createdAt.toIso8601String(),
      'login_time': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  // Get current user session
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      
      if (sessionData == null) return null;

      final data = jsonDecode(sessionData);
      final loginTime = DateTime.parse(data['login_time']);
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      // Check if session is still valid
      if (!rememberMe) {
        final sessionDuration = DateTime.now().difference(loginTime);
        if (sessionDuration.inHours > 24) {
          await logout();
          return null;
        }
      }

      return User(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        passwordHash: '', // Don't store password hash in session
        profileImage: data['profile_image'],
        createdAt: DateTime.parse(data['created_at']),
      );
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_rememberMeKey);
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required User user,
    String? newUsername,
    String? newEmail,
    String? newPassword,
    String? profileImage,
  }) async {
    try {
      final db = DatabaseService.instance;
      
      // Check if new username is already taken
      if (newUsername != null && newUsername != user.username) {
        final existingUser = await db.getUserByUsername(newUsername);
        if (existingUser != null) {
          return {'success': false, 'message': 'Username already exists'};
        }
      }

      // Check if new email is already taken
      if (newEmail != null && newEmail != user.email) {
        if (!_isValidEmail(newEmail)) {
          return {'success': false, 'message': 'Please enter a valid email'};
        }
        final existingUser = await db.getUserByEmail(newEmail);
        if (existingUser != null) {
          return {'success': false, 'message': 'Email already registered'};
        }
      }

      // Update user
      final updatedUser = user.copyWith(
        username: newUsername ?? user.username,
        email: newEmail ?? user.email,
        passwordHash: newPassword != null ? _encryptPassword(newPassword) : user.passwordHash,
        profileImage: profileImage ?? user.profileImage,
      );

      await db.updateUser(updatedUser);
      
      // Update session
      await _saveSession(updatedUser, true);

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Update failed: $e'};
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required User user,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Verify current password
      final currentHash = _encryptPassword(currentPassword);
      if (user.passwordHash != currentHash) {
        return {'success': false, 'message': 'Current password is incorrect'};
      }

      if (newPassword != confirmPassword) {
        return {'success': false, 'message': 'New passwords do not match'};
      }

      if (newPassword.length < 6) {
        return {'success': false, 'message': 'Password must be at least 6 characters'};
      }

      // Update password
      final db = DatabaseService.instance;
      final updatedUser = user.copyWith(passwordHash: _encryptPassword(newPassword));
      await db.updateUser(updatedUser);

      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Password change failed: $e'};
    }
  }

  // Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Reset session timeout
  static Future<void> refreshSession() async {
    final user = await getCurrentUser();
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      await _saveSession(user, rememberMe);
    }
  }
} 
