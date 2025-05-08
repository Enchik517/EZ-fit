import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS
        ? '543784915804-mvhe2hbph5ad7vmsb38950gih4rgb6pv.apps.googleusercontent.com'
        : null,
    serverClientId:
        '543784915804-mvhe2hbph5ad7vmsb38950gih4rgb6pv.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in canceled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Could not get auth token');
      }

      // Store Google user data for later use in user creation
      final Map<String, dynamic> userData = {
        'email': googleUser.email,
        'full_name': googleUser.displayName,
        'avatar_url': googleUser.photoUrl,
      };

      // Store in Supabase auth metadata
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Сохраняем данные пользователя Google для последующего использования
      if (response.user != null) {
        await _supabase.from('auth_metadata').upsert({
          'id': response.user!.id,
          'google_data': userData,
        });

        // После успешной аутентификации обновляем имя пользователя в профиле
        if (googleUser.displayName != null &&
            googleUser.displayName!.isNotEmpty) {
          // Обновляем метаданные пользователя
          await _supabase.auth.updateUser(UserAttributes(
            data: {'full_name': googleUser.displayName},
          ));

          // Также обновляем имя в таблице профилей, если профиль существует
          try {
            await _supabase
                .from('user_profiles')
                .update({'full_name': googleUser.displayName}).eq(
                    'id', response.user!.id);
            debugPrint(
                'Имя пользователя обновлено из Google: ${googleUser.displayName}');
          } catch (e) {
            debugPrint('Ошибка при обновлении имени в профиле: $e');
          }
        }
      }

      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<AuthResponse?> signInWithApple() async {
    try {
      // Проверяем доступность Apple Sign In (только на iOS/macOS или в интернете)
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable && !kIsWeb) {
        throw UnsupportedError('Apple Sign In is not available on this device');
      }

      // Получаем учетные данные Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Если нет idToken или authCode, выход
      if (credential.identityToken == null ||
          credential.authorizationCode == null) {
        throw Exception('Failed to get valid Apple Sign In credentials');
      }

      // Аутентификация с Supabase через Apple OAuth
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      if (response.user != null) {
        // Обновляем имя пользователя, если предоставлено Apple
        if (credential.givenName != null && credential.familyName != null) {
          final fullName =
              '${credential.givenName} ${credential.familyName}'.trim();
          if (fullName.isNotEmpty) {
            await _supabase.auth.updateUser(UserAttributes(
              data: {'full_name': fullName},
            ));
          }
        }
        notifyListeners();
      }

      return response;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Проверка наличия активной сессии
      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null) {
        debugPrint('No active session found during signOut');
      }

      // Выполнение выхода из системы
      await _supabase.auth.signOut();

      // Проверка успешности выхода
      final postSignOutUser = _supabase.auth.currentUser;
      if (postSignOutUser != null) {
        debugPrint('Warning: User still detected after signOut, retrying...');
        await _supabase.auth.signOut();
      }

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Возвращает текущий Google аккаунт, если пользователь авторизован через Google
  Future<Map<String, dynamic>?> getGoogleUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('auth_metadata')
          .select('google_data')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response.containsKey('google_data')) {
        return response['google_data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting Google user data: $e');
      return null;
    }
  }

  // Получает данные пользователя из метаданных Apple аутентификации
  Future<Map<String, dynamic>?> getAppleUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('auth_metadata')
          .select('apple_data')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response.containsKey('apple_data')) {
        return response['apple_data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting Apple user data: $e');
      return null;
    }
  }
}
