import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.password,
    String? fullName,
    String? phoneNumber,
  })  : fullName = fullName ?? '',
        phoneNumber = phoneNumber ?? '';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  final String id;
  String displayName;
  final String email;
  final String password;
  String fullName;
  String phoneNumber;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'displayName': displayName,
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      };
}

class AccountController extends ChangeNotifier {
  AccountController._internal();

  static final AccountController instance = AccountController._internal();

  static const _keyUsers = 'account.users';
  static const _keyCurrentUserId = 'account.currentUserId';

  late SharedPreferences _prefs;
  bool _initialized = false;

  final List<UserProfile> _users = <UserProfile>[];
  UserProfile? _currentUser;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
    _initialized = true;
  }

  void _loadFromPrefs() {
    final usersJson = _prefs.getString(_keyUsers);
    if (usersJson != null && usersJson.isNotEmpty) {
      final raw = jsonDecode(usersJson) as List;
      _users
        ..clear()
        ..addAll(
          raw.map((dynamic e) => UserProfile.fromJson(e as Map<String, dynamic>)),
        );
    }

    final currentUserId = _prefs.getString(_keyCurrentUserId);
    _currentUser =
        _users.firstWhereOrNull((user) => user.id == currentUserId);
    notifyListeners();
  }

  List<UserProfile> get users => List.unmodifiable(_users);
  UserProfile? get currentUser => _currentUser;

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
      return false;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final profile = UserProfile(
      id: id,
      displayName: displayName,
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    _users.add(profile);
    await _persistUsers();
    await login(email: email, password: password);
    return true;
  }

  Future<bool> login({required String email, required String password}) async {
    final profile = _users.firstWhereOrNull(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );
    if (profile == null || profile.password != password) {
      return false;
    }
    _currentUser = profile;
    await _prefs.setString(_keyCurrentUserId, profile.id);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove(_keyCurrentUserId);
    notifyListeners();
  }

  Future<void> updateDisplayName(String value) async {
    await updateProfile(displayName: value);
  }

  Future<void> updateProfile({
    String? displayName,
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return;
    var changed = false;
    if (displayName != null) {
      final trimmed = displayName.trim();
      if (trimmed.isNotEmpty && _currentUser!.displayName != trimmed) {
        _currentUser!.displayName = trimmed;
        changed = true;
      }
    }
    if (fullName != null) {
      final trimmed = fullName.trim();
      if (_currentUser!.fullName != trimmed) {
        _currentUser!.fullName = trimmed;
        changed = true;
      }
    }
    if (phoneNumber != null) {
      final trimmed = phoneNumber.trim();
      if (_currentUser!.phoneNumber != trimmed) {
        _currentUser!.phoneNumber = trimmed;
        changed = true;
      }
    }
    if (!changed) return;
    await _persistUsers();
    notifyListeners();
  }

  Future<void> _persistUsers() async {
    final encoded = jsonEncode(_users.map((user) => user.toJson()).toList());
    await _prefs.setString(_keyUsers, encoded);
  }
}

extension FirstWhereOrNullAccount<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
