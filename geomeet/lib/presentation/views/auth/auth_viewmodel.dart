import 'package:flutter/foundation.dart';
import '../../../services/auth/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../services/firebase/database/firebase_database_service.dart';

class AuthViewModel with ChangeNotifier {
  final AuthService _authService;
  final FirebaseDatabaseService? _dbService;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authService, [this._dbService]);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      _authService.userState.listen((user) {
        _currentUser = user;
        notifyListeners();
      });
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: ${e.toString()}');
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        username: username,
      );

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      if (user != null && _dbService != null) {
        await _dbService.setUserActive(true);
      }

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_dbService != null) {
        await _dbService.setUserActive(false);
      }
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
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

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
