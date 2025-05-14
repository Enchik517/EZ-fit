import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../services/chat_service.dart';
import 'package:flutter/rendering.dart';
import '../main.dart'; // Для доступа к navigatorKey

class AuthProvider with ChangeNotifier {
  final _profileService = ProfileService();
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final WorkoutProvider workoutProvider;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _hasAcceptedDisclaimer = false;
  bool _isNewUser = false;

  AuthProvider(this.workoutProvider) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Загружаем текущего пользователя
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _user = user;
        _isNewUser = !(await hasCompletedSurvey());

        // Загружаем профиль пользователя
        await loadUserProfile();
      }
    } catch (e) {
      debugPrint('Error initializing AuthProvider: $e');
    }
  }

  User? get user {
    if (_user == null) {
      _user = _supabase.auth.currentUser;
      if (_user != null && _userProfile == null) {
        loadUserProfile();
      }
    }
    return _user;
  }

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get hasAcceptedDisclaimer => _hasAcceptedDisclaimer;
  bool get isNewUser => _isNewUser;

  void setDisclaimerAccepted(bool accepted) {
    _hasAcceptedDisclaimer = accepted;
    notifyListeners();
  }

  Future<void> setUser(User? user) async {
    _user = user;
    if (user != null) {
      // Wait until the user appears in the database
      await Future.delayed(const Duration(milliseconds: 500));
      await loadUserProfile();
    } else {
      _userProfile = null;
      _hasAcceptedDisclaimer = false;
    }
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    try {
      debugPrint('=== [loadUserProfile] Начало загрузки профиля ===');
      _isLoading = true;
      notifyListeners();

      if (_user == null) {
        debugPrint(
            '[loadUserProfile] Пользователь не авторизован, пробуем получить из сессии');

        // Пробуем получить пользователя из сессии
        final sessionUser = await _supabase.auth.getUser();
        if (sessionUser.user != null) {
          _user = sessionUser.user;
          debugPrint(
              '[loadUserProfile] Пользователь получен из сессии: ${_user!.id}');
        } else {
          debugPrint(
              '[loadUserProfile] ОШИБКА: Невозможно получить пользователя, сессия отсутствует');
          _userProfile = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      debugPrint(
          '[loadUserProfile] Загрузка профиля для пользователя: ${_user!.id}');

      // Загружаем данные профиля из базы данных
      try {
        debugPrint('[loadUserProfile] Отправляем запрос к базе данных');
        final response = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', _user!.id)
            .single();

        debugPrint('[loadUserProfile] Ответ получен: $response');

        if (response == null) {
          debugPrint('[loadUserProfile] Профиль не найден, создаем новый');
          // Создаем профиль, если его нет
          await _createUserProfile(_user!);
        } else {
          _userProfile = UserProfile.fromJson(response);
          debugPrint('[loadUserProfile] Профиль загружен: ${_userProfile!.id}');
        }
      } catch (e) {
        if (e is PostgrestException && e.code == 'PGRST116') {
          debugPrint('[loadUserProfile] Профиль не найден, создаем новый');
          // Создаем профиль, если его нет
          await _createUserProfile(_user!);
        } else {
          debugPrint('[loadUserProfile] Ошибка при загрузке профиля: $e');
          throw e;
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке профиля: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      if (response == null) {
        debugPrint('Профиль не найден для пользователя: $userId');
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      // Если ошибка PostgrestException с кодом PGRST116, значит запись не найдена
      if (e is PostgrestException && e.code == 'PGRST116') {
        debugPrint('Профиль не найден, создаем новый');
        // Создаем начальный профиль
        await _createInitialProfile();
        // Повторно пробуем получить профиль
        return await getUserProfile(userId);
      }
      return null;
    }
  }

  Future<bool> hasCompletedSurvey() async {
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('has_completed_survey')
          .eq('id', user!.id)
          .maybeSingle();

      // Безопасно обрабатываем null значение
      return response != null &&
          response.containsKey('has_completed_survey') &&
          response['has_completed_survey'] == true;
    } catch (e) {
      debugPrint('Error checking survey completion: $e');
      return false;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      debugPrint('Сохраняем профиль: ${profile.id}');
      debugPrint('hasCompletedSurvey = ${profile.hasCompletedSurvey}');

      // Принудительно убеждаемся, что в базе данных флаг установлен правильно
      if (profile.hasCompletedSurvey) {
        await _supabase
            .from('user_profiles')
            .update({'has_completed_survey': true}).eq('id', profile.id);

        debugPrint('Принудительно обновили has_completed_survey в базе');

        // Сохраняем флаг в метаданных пользователя
        await updateSurveyCompletionFlag(true);
      }

      // Сохраняем полный профиль
      await _supabase
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);

      debugPrint('Профиль сохранен через Supabase');

      // Обновляем локальный профиль
      _userProfile = profile;

      // Если hasCompletedSurvey == true, то пользователь больше не новый
      if (profile.hasCompletedSurvey) {
        _isNewUser = false;
        debugPrint(
            'Profile saved with completed survey, isNewUser set to false');
      }

      notifyListeners();
      debugPrint('Профиль успешно сохранен!');
    } catch (e) {
      debugPrint('Ошибка при сохранении профиля: $e');
      rethrow;
    }
  }

  // Новый метод для обновления флага завершения опроса в метаданных пользователя
  Future<void> updateSurveyCompletionFlag(bool completed) async {
    try {
      if (_user == null) return;

      // Получаем текущие метаданные
      final currentMetadata = _user!.userMetadata ?? {};

      // Добавляем или обновляем флаг завершения опроса
      final updatedMetadata = {
        ...currentMetadata,
        'has_completed_survey': completed,
      };

      // Обновляем метаданные пользователя
      await _supabase.auth.updateUser(
        UserAttributes(
          data: updatedMetadata,
        ),
      );

      debugPrint('Флаг завершения опроса обновлен в метаданных пользователя');
    } catch (e) {
      debugPrint('Ошибка при обновлении метаданных пользователя: $e');
    }
  }

  // Проверка флага завершения опроса в метаданных пользователя
  bool hasSurveyCompletionFlag() {
    if (_user == null || _user!.userMetadata == null) return false;

    // Проверяем наличие флага в метаданных
    final metadata = _user!.userMetadata!;
    return metadata['has_completed_survey'] == true;
  }

  // Принудительно проверяет флаг завершения опроса непосредственно в базе данных
  Future<bool> checkSurveyCompletionInDatabase() async {
    if (_user == null) return false;

    try {
      // Проверяем профиль в базе данных
      final response = await _supabase
          .from('user_profiles')
          .select('has_completed_survey')
          .eq('id', _user!.id)
          .single();

      final hasCompletedSurveyInDb = response['has_completed_survey'] == true;
      debugPrint('Флаг has_completed_survey в базе: $hasCompletedSurveyInDb');

      // Проверяем метаданные пользователя
      final userData = await _supabase.auth.getUser();
      final userMetadata = userData.user?.userMetadata;
      final hasCompletedSurveyInMeta =
          userMetadata != null && userMetadata['has_completed_survey'] == true;

      debugPrint(
          'Флаг has_completed_survey в метаданных: $hasCompletedSurveyInMeta');

      // Если хотя бы один флаг установлен, возвращаем true
      return hasCompletedSurveyInDb || hasCompletedSurveyInMeta;
    } catch (e) {
      debugPrint('Ошибка при проверке завершения опроса в базе: $e');
      // Если ошибка PostgrestException с кодом PGRST116, значит запись не найдена
      if (e is PostgrestException && e.code == 'PGRST116') {
        debugPrint('Профиль не найден при проверке, создаем новый');
        // Создаем начальный профиль
        await _createInitialProfile();
        return false;
      }
      return false;
    }
  }

  // Метод для принудительной проверки флага hasCompletedSurvey в базе данных
  Future<bool> forceCheckSurveyCompletionInDatabase() async {
    try {
      if (_user == null) {
        debugPrint(
            'forceCheckSurveyCompletionInDatabase: Пользователь не авторизован');
        return false;
      }

      debugPrint(
          'forceCheckSurveyCompletionInDatabase: Проверяем для пользователя ${_user!.id}');

      // Напрямую проверяем значение в базе данных
      try {
        final response = await _supabase
            .from('user_profiles')
            .select('has_completed_survey')
            .eq('id', _user!.id)
            .single();

        // Безопасно обрабатываем null значения
        final hasCompletedSurvey =
            (response.containsKey('has_completed_survey') &&
                response['has_completed_survey'] == true);

        debugPrint(
            'forceCheckSurveyCompletionInDatabase: Значение в базе данных has_completed_survey = ${response['has_completed_survey']}');

        // Обновляем профиль в памяти, если он загружен
        if (_userProfile != null &&
            _userProfile!.hasCompletedSurvey != hasCompletedSurvey) {
          debugPrint(
              'forceCheckSurveyCompletionInDatabase: Обновляем значение hasCompletedSurvey в памяти с ${_userProfile!.hasCompletedSurvey} на $hasCompletedSurvey');
          _userProfile =
              _userProfile!.copyWith(hasCompletedSurvey: hasCompletedSurvey);
          notifyListeners();
        }

        return hasCompletedSurvey;
      } catch (e) {
        debugPrint('Ошибка при получении профиля: $e');
        // Если ошибка PostgrestException с кодом PGRST116, значит запись не найдена
        if (e is PostgrestException && e.code == 'PGRST116') {
          debugPrint('Профиль не найден, создаем новый');
          // Создаем начальный профиль
          await _createInitialProfile();
          // Возвращаем false, так как новый профиль создан без завершенного опроса
          return false;
        }
        // Пробуем создать профиль после другой ошибки
        await _createInitialProfile();
        return false;
      }
    } catch (e) {
      debugPrint('forceCheckSurveyCompletionInDatabase: Ошибка - $e');
      return false;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    if (user == null) throw Exception('No user logged in');

    try {
      _isLoading = true;
      notifyListeners();

      final profileData = profile.toJson();
      await _supabase
          .from('user_profiles')
          .update(profileData)
          .eq('id', user!.id);
      _userProfile = profile;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Инициализация при запуске
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Проверяем текущего пользователя
      _user = _supabase.auth.currentUser;

      debugPrint(
          'AuthProvider initialize: Текущий пользователь: ${_user?.id ?? "NULL"}');

      if (_user != null) {
        // Загружаем профиль пользователя
        await loadUserProfile();

        // Проверяем и синхронизируем флаг завершения опроса
        await syncSurveyCompletionFlag();

        // Если пользователь вошел через Google, синхронизируем его профиль с текущими данными Google
        final userData = await _supabase.auth.getUser();
        final identities = userData.user?.identities;

        if (identities != null) {
          bool isGoogleUser =
              identities.any((identity) => identity.provider == 'google');

          if (isGoogleUser && _userProfile != null) {
            debugPrint(
                'Обнаружен пользователь Google, синхронизируем данные профиля');
            await _updateProfileFromGoogle(_user!);
          }
        }

        // Загружаем статистику
        await workoutProvider.loadStatistics();
      } else {
        // Пробуем получить пользователя другим способом, если _user == null
        final authStateUser = (await _supabase.auth.getUser()).user;
        if (authStateUser != null) {
          debugPrint('Получен пользователь через getUser: ${authStateUser.id}');
          _user = authStateUser;
          await loadUserProfile();
        } else {
          debugPrint('Невозможно получить текущего пользователя');
        }
      }

      // Инициализируем слушатель изменений сессии
      _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn) {
          setUser(session?.user);

          // При входе обновляем статистику
          await workoutProvider.loadStatistics();
        } else if (event == AuthChangeEvent.signedOut) {
          setUser(null);
        }
      });
    } catch (e) {
      debugPrint('Error initializing AuthProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Синхронизация флага завершения опроса между профилем и метаданными
  Future<void> syncSurveyCompletionFlag() async {
    if (_user == null || _userProfile == null) return;

    try {
      // Проверяем флаг в профиле
      final hasCompletedSurveyInProfile = _userProfile!.hasCompletedSurvey;

      // Проверяем флаг в метаданных
      final hasCompletedSurveyInMeta = hasSurveyCompletionFlag();

      debugPrint(
          'Синхронизация флагов: в профиле = $hasCompletedSurveyInProfile, в метаданных = $hasCompletedSurveyInMeta');

      // Если хотя бы один из флагов true, устанавливаем оба в true
      if (hasCompletedSurveyInProfile || hasCompletedSurveyInMeta) {
        // Если флаг в профиле не установлен, обновляем профиль
        if (!hasCompletedSurveyInProfile) {
          final updatedProfile =
              _userProfile!.copyWith(hasCompletedSurvey: true);
          await saveUserProfile(updatedProfile);
          debugPrint('Флаг в профиле обновлен: hasCompletedSurvey = true');
        }

        // Если флаг в метаданных не установлен, обновляем метаданные
        if (!hasCompletedSurveyInMeta) {
          await updateSurveyCompletionFlag(true);
          debugPrint('Флаг в метаданных обновлен: has_completed_survey = true');
        }
      }

      // Дополнительная проверка наличия тренировок
      final logs = await _supabase
          .from('workout_logs')
          .select('id')
          .eq('user_id', _user!.id)
          .limit(1);

      if (logs != null &&
          logs.isNotEmpty &&
          (!hasCompletedSurveyInProfile || !hasCompletedSurveyInMeta)) {
        debugPrint(
            'Обнаружены логи тренировок, устанавливаем флаги завершения опроса');

        // Обновляем профиль
        if (!hasCompletedSurveyInProfile) {
          final updatedProfile =
              _userProfile!.copyWith(hasCompletedSurvey: true);
          await saveUserProfile(updatedProfile);
        }

        // Обновляем метаданные
        if (!hasCompletedSurveyInMeta) {
          await updateSurveyCompletionFlag(true);
        }
      }
    } catch (e) {
      debugPrint('Ошибка при синхронизации флага завершения опроса: $e');
    }
  }

  Future<bool> checkAuth() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session != null && session.isExpired) {
        // Если сессия истекла, пытаемся обновить
        await _supabase.auth.refreshSession();
      }

      final isAuthenticated = _supabase.auth.currentSession != null;

      if (isAuthenticated && _user == null) {
        _user = _supabase.auth.currentUser;
        if (_user != null && _userProfile == null) {
          await loadUserProfile();
        }
      }

      return isAuthenticated;
    } catch (e) {
      debugPrint('Error checking auth: $e');
      return false;
    }
  }

  // Метод для удаления аккаунта
  Future<void> deleteAccount() async {
    try {
      print('Starting account deletion...');

      // Вызываем SQL функцию для удаления всех данных пользователя
      await Supabase.instance.client.rpc('delete_user_account');

      print('SQL function executed successfully');

      // Сбрасываем состояние провайдера
      _user = null;
      _userProfile = null;
      _hasAcceptedDisclaimer = false;
      _isNewUser = false;

      // Выходим из аккаунта
      await signOut();

      print('Account deletion completed successfully');

      // Используем navigatorKey для перенаправления на экран входа
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      print('Error deleting account: $e');
      _isLoading = false;
      rethrow;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    // Удаляем этот метод, так как он нужен только для email-аутентификации
  }

  Future<void> updateWorkoutStats({
    required int addSets,
    required double addHours,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _profileService.updateWorkoutStats(
        userId: userId,
        addSets: addSets,
        addHours: addHours,
      );

      await loadUserProfile(); // Перезагружаем профиль
    } catch (e) {
      print('Error updating workout stats: $e');
      rethrow;
    }
  }

  // Метод для входа через Apple ID
  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Попытка входа через Apple...');
      final response = await _authService.signInWithApple();

      if (response != null && response.user != null) {
        debugPrint('Успешный вход через Apple: ${response.user!.id}');
        // Устанавливаем текущего пользователя в провайдере
        _user = response.user;

        // Отправляем запрос к базе за профилем пользователя
        await loadUserProfile();

        // Проверяем наличие профиля - если нет, то пользователь новый
        if (_userProfile == null) {
          debugPrint('Создаем новый профиль пользователя для Apple Sign In');
          await _createUserProfile(response.user!);
          _isNewUser = true;
          await loadUserProfile();
        } else {
          // Даже если профиль существует, но опрос не пройден, считаем пользователя "новым"
          _isNewUser = _userProfile?.hasCompletedSurvey == false;
          debugPrint(
              'Apple Sign In: Существующий пользователь, hasCompletedSurvey: ${_userProfile?.hasCompletedSurvey}, установлен isNewUser: $_isNewUser');
        }

        notifyListeners();
        return true;
      } else {
        debugPrint('Не удалось получить пользователя после Apple Sign In');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка при входе через Apple: $e');

      // Проверяем, не является ли ошибка отменой авторизации
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('cancel')) {
        // Это отмена входа, очищаем состояние пользователя
        _user = null;
        _userProfile = null;
        notifyListeners();
        // Пробрасываем ошибку, чтобы обработчик в UI знал, что вход был отменен
        throw Exception('auth_cancelled');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Метод для входа через Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Попытка входа через Google...');
      final response = await _authService.signInWithGoogle();

      if (response.user != null) {
        debugPrint('Успешный вход через Google: ${response.user!.id}');
        // Устанавливаем текущего пользователя в провайдере
        _user = response.user;

        // Отправляем запрос к базе за профилем пользователя
        await loadUserProfile();

        // Проверяем наличие профиля - если нет, то пользователь новый
        if (_userProfile == null) {
          debugPrint('Создаем новый профиль пользователя для Google Sign In');
          await _createUserProfile(response.user!);
          _isNewUser = true;
          await loadUserProfile();
        } else {
          // Обновляем имя пользователя из Google, если оно изменилось
          await _updateProfileFromGoogle(response.user!);

          // Даже если профиль существует, но опрос не пройден, считаем пользователя "новым"
          _isNewUser = _userProfile?.hasCompletedSurvey == false;
          debugPrint(
              'Google Sign In: Существующий пользователь, hasCompletedSurvey: ${_userProfile?.hasCompletedSurvey}, установлен isNewUser: $_isNewUser');
        }

        notifyListeners();
        return true;
      } else {
        debugPrint('Не удалось получить пользователя после Google Sign In');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка при входе через Google: $e');

      // Проверяем, не является ли ошибка отменой авторизации
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('cancel')) {
        // Это отмена входа, очищаем состояние пользователя
        _user = null;
        _userProfile = null;
        notifyListeners();
        // Пробрасываем ошибку, чтобы обработчик в UI знал, что вход был отменен
        throw Exception('auth_cancelled');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Новый метод для обновления профиля из Google данных
  Future<void> _updateProfileFromGoogle(User user) async {
    try {
      if (_userProfile == null) return;

      // Получаем актуальные данные из Google
      final googleData = await _authService.getGoogleUserData();

      // Проверяем метаданные пользователя для получения текущего имени
      final userData = await _supabase.auth.getUser();
      final userMetadata = userData.user?.userMetadata;
      String? currentUserName = userMetadata?['full_name'];

      // Получаем имя из Google данных
      String? googleName = googleData?['full_name'];

      // Если имя в Google изменилось и отличается от имени в профиле
      if (googleName != null &&
          googleName.isNotEmpty &&
          googleName != _userProfile!.fullName) {
        debugPrint(
            'Обновляем имя пользователя из Google: $googleName (старое: ${_userProfile!.fullName})');

        // Обновляем метаданные пользователя
        await _supabase.auth.updateUser(UserAttributes(
          data: {'full_name': googleName},
        ));

        // Обновляем профиль в базе данных
        await _supabase
            .from('user_profiles')
            .update({'full_name': googleName}).eq('id', user.id);

        // Обновляем локальный профиль
        _userProfile = _userProfile!.copyWith(fullName: googleName);

        debugPrint('Имя пользователя успешно обновлено из Google');
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении имени из Google: $e');
    }
  }

  // Создание нового профиля пользователя
  Future<void> _createUserProfile(User user) async {
    debugPrint(
        '[_createUserProfile] Создаем новый профиль для пользователя: ${user.id}');

    // Получаем данные из метаданных пользователя
    String? fullName;
    String? email = user.email;

    if (user.userMetadata != null) {
      final metadata = user.userMetadata!;
      if (metadata.containsKey('full_name')) {
        fullName = metadata['full_name'] as String?;
      } else if (metadata.containsKey('name')) {
        fullName = metadata['name'] as String?;
      }
    }

    // Если имя не найдено, используем часть email или ID
    fullName ??= email?.split('@').first ?? user.id.substring(0, 6);

    // Создаем новый профиль
    final newProfile = UserProfile(
      id: user.id,
      email: email,
      fullName: fullName,
      hasCompletedSurvey: false,
      fitnessLevel: null,
      goals: [],
      weeklyWorkouts: 'WorkoutFrequency.none',
      workoutDuration: '30-45 minutes',
      totalSets: 0,
      totalWorkouts: 0,
      totalHours: 0,
      workoutStreak: 0,
      birthDate: DateTime.now()
          .subtract(const Duration(days: 365 * 25)), // Примерный возраст 25 лет
    );

    try {
      // Вставляем профиль в базу данных
      await _supabase.from('user_profiles').insert({
        'id': user.id,
        'email': email,
        'full_name': fullName,
        'has_completed_survey': false,
        'birth_date': DateTime.now()
            .subtract(const Duration(days: 365 * 25))
            .toIso8601String(),
        'fitness_level': 'Beginner',
        'goals': [],
        'equipment': [],
        'weekly_workouts': 'WorkoutFrequency.none',
        'workout_duration': '30-45 minutes',
        'workout_streak': 0,
        'total_workouts': 0,
        'total_sets': 0,
        'total_hours': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Устанавливаем профиль в памяти
      _userProfile = newProfile;
      debugPrint('[_createUserProfile] Профиль успешно создан');
    } catch (e) {
      debugPrint('[_createUserProfile] Ошибка при создании профиля: $e');
      throw e;
    }
  }

  Future<void> _createInitialProfile() async {
    if (_user != null) {
      await _createUserProfile(_user!);
    } else {
      throw Exception('No user logged in');
    }
  }

  // Метод для выхода из аккаунта
  Future<void> signOut() async {
    try {
      _isLoading = true;
      // Не вызываем notifyListeners() здесь, чтобы избежать двойной индикации загрузки

      debugPrint('Signing out user...');

      // Проверяем, есть ли активная сессия
      final currentSession = _supabase.auth.currentSession;
      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        debugPrint('Current user found: ${currentUser.id}');
      } else {
        debugPrint('No active user found');
      }

      if (currentSession != null) {
        debugPrint('Current session found, signing out');
      } else {
        debugPrint('No active session found');
      }

      // Сбрасываем сервис чата (если доступен в контексте)
      try {
        final chatService = Provider.of<ChatService>(
            navigatorKey.currentContext!,
            listen: false);
        chatService.reset();
        debugPrint('Chat service reset successfully');
      } catch (e) {
        debugPrint('Could not reset chat service: $e');
      }

      // Выполняем выход
      await _supabase.auth.signOut();
      debugPrint('Supabase auth signOut completed');

      // Проверяем, действительно ли пользователь вышел
      final postSignOutUser = _supabase.auth.currentUser;
      if (postSignOutUser == null) {
        debugPrint('Sign out successful: no current user detected');
      } else {
        debugPrint(
            'Warning: User still detected after signOut: ${postSignOutUser.id}');
      }

      // Сбрасываем данные пользователя
      _user = null;
      _userProfile = null;
      _hasAcceptedDisclaimer = false;

      debugPrint('User signed out successfully');

      // Обновляем UI, чтобы приложение знало, что пользователь вышел
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
