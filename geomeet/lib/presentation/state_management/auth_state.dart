 
import 'package:flutter/foundation.dart';
import 'package:geomeet/services/auth/auth_service.dart';
import 'package:geomeet/data/models/user_model.dart';

class AuthState with ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthState(this._authService);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _authService.userState.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<Object?> login(String email, String password) async {
    _setLoading(true);
    try {
      final success = await _authService.login(email: email, password: password);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<Object?> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      final success = await _authService.register(
        email: email,
        password: password,
        username: username,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}