import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geomeet/services/firebase/database/firebase_database_service.dart';
import 'package:geomeet/data/models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseDatabaseService _database;

  AuthService(this._database) : _auth = firebase_auth.FirebaseAuth.instance;

  Stream<User?> get userState {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        return await _database.getUser(firebaseUser.uid);
      } catch (e) {
        throw AuthException('Failed to fetch user data: ${e.toString()}');
      }
    });
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        return await _database.getUser(credential.user!.uid);
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Échec de la connexion: ${e.toString()}');
    }
  }

  Future<User?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Vérification supplémentaire
      if (username.isEmpty || username.length < 3) {
        throw AuthException('Le nom d\'utilisateur doit contenir au moins 3 caractères');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        final newUser = User(
          id: credential.user!.uid,
          username: username.trim(),
          email: email.trim(),
          profilPicture: null,
        );

        await _database.createUser(newUser);
        return newUser;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Échec de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Échec de la déconnexion: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        throw AuthException('Veuillez entrer un email valide');
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Échec de l\'envoi de l\'email de réinitialisation: ${e.toString()}');
    }
  }

  String _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'network-request-failed':
        return 'Problème de connexion internet';
      default:
        return 'Erreur d\'authentification: ${e.message ?? e.code}';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}