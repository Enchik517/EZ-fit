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
      _isLoading = true;
      notifyListeners();

      if (_user == null) {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Загрузка профиля для пользователя: ${_user!.id}');

      // Загружаем данные профиля из базы
      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', _user!.id)
          .single();

      if (response != null) {
        debugPrint('Получен профиль из базы данных: ${response['id']}');
        debugPrint(
            'Значение has_completed_survey в базе: ${response['has_completed_survey']}');

        // ВАЖНО: принудительно устанавливаем has_completed_survey из базы данных
        bool hasCompletedFromDb = response['has_completed_survey'] == true;

        _userProfile = UserProfile.fromJson(response);

        // Если значение hasCompletedSurvey в профиле не совпадает с базой
        if (_userProfile!.hasCompletedSurvey != hasCompletedFromDb) {
          debugPrint(
              'Внимание: hasCompletedSurvey в профиле (${_userProfile!.hasCompletedSurvey}) ' +
                  'не соответствует значению в базе данных ($hasCompletedFromDb)');

          // Корректируем значение в профиле
          _userProfile =
              _userProfile!.copyWith(hasCompletedSurvey: hasCompletedFromDb);
          debugPrint(
              'Исправлено значение в профиле: hasCompletedSurvey = ${_userProfile!.hasCompletedSurvey}');
        }

        // Проверяем метаданные пользователя для синхронизации имени
        final userData = await _supabase.auth.getUser();
        if (userData.user?.userMetadata != null) {
          final userMetadata = userData.user!.userMetadata!;

          // Если в метаданных есть имя, и оно отличается от имени в профиле
          if (userMetadata['full_name'] != null &&
              userMetadata['full_name'] != _userProfile!.fullName) {
            debugPrint(
                'Обновляем имя в профиле из метаданных аутентификации: ${userMetadata['full_name']}');

            // Обновляем имя в базе данных
            await _supabase.from('user_profiles').update(
                {'full_name': userMetadata['full_name']}).eq('id', _user!.id);

            // Обновляем локальный профиль
            _userProfile =
                _userProfile!.copyWith(fullName: userMetadata['full_name']);
          }
        }

        // Явная проверка на hasCompletedSurvey
        final hasCompletedSurveyValue = response['has_completed_survey'];
        debugPrint(
            'Загружен профиль, has_completed_survey из базы: $hasCompletedSurveyValue');
        debugPrint(
            'После конвертации hasCompletedSurvey = ${_userProfile!.hasCompletedSurvey}');

        // Проверка наличия logs как индикатора пройденного опроса
        final logs = await _supabase
            .from('workout_logs')
            .select('id')
            .eq('user_id', _user!.id)
            .limit(1);

        // Если есть логи тренировок, то опрос точно должен быть пройден
        if (logs != null &&
            logs.isNotEmpty &&
            !_userProfile!.hasCompletedSurvey) {
          debugPrint(
              'У пользователя есть логи тренировок, но hasCompletedSurvey = false. Исправляем...');
          final updatedProfile =
              _userProfile!.copyWith(hasCompletedSurvey: true);
          await saveUserProfile(updatedProfile);
        }
      } else {
        debugPrint('Профиль не найден в базе данных');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке профиля: $e');
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

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
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
          .single();

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

  Future<void> _createUserProfile(User user) async {
    try {
      print(
          '_createUserProfile: Создаю профиль для нового пользователя ${user.id}');

      // Получаем данные из Google аккаунта
      final googleData = await _authService.getGoogleUserData();

      // Значения по умолчанию
      String? userName = user.email?.split('@')[0] ?? 'User';
      String? avatarUrl;

      // Если есть данные из Google, используем их
      if (googleData != null) {
        userName = googleData['full_name'] ?? userName;
        avatarUrl = googleData['avatar_url'];
      }

      // Дополнительно проверяем метаданные пользователя
      final userData = await _supabase.auth.getUser();
      final userMetadata = userData.user?.userMetadata;
      if (userMetadata != null && userMetadata['full_name'] != null) {
        // Приоритет отдаем имени в метаданных (оно наиболее актуальное)
        userName = userMetadata['full_name'] ?? userName;
        debugPrint('Используем имя из метаданных пользователя: $userName');
      }

      final defaultBirthDate =
          DateTime.now().subtract(const Duration(days: 365 * 25));

      // Сначала проверяем, есть ли уже профиль в базе
      try {
        final existingProfile = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        if (existingProfile != null) {
          print(
              '_createUserProfile: Профиль уже существует, обновляем hasCompletedSurvey=false');

          // Обновляем имя пользователя, если оно изменилось в Google аккаунте
          if (userName != null && userName != existingProfile['full_name']) {
            await _supabase.from('user_profiles').update({
              'has_completed_survey': false,
              'full_name': userName
            }).eq('id', user.id);
            debugPrint(
                '_createUserProfile: Обновлено имя пользователя: $userName');
          } else {
            // Принудительно обновляем hasCompletedSurvey в базе
            await _supabase
                .from('user_profiles')
                .update({'has_completed_survey': false}).eq('id', user.id);
          }

          // Обновляем метаданные пользователя
          await _supabase.auth.updateUser(UserAttributes(
            data: {'has_completed_survey': false, 'full_name': userName},
          ));

          print('_createUserProfile: Флаги обновлены');
          return;
        }
      } catch (e) {
        print(
            '_createUserProfile: Ошибка при проверке существующего профиля: $e');
      }

      // Создаем профиль с hasCompletedSurvey = false
      final profile = UserProfile(
        id: user.id,
        email: user.email,
        fullName: userName,
        avatarUrl: avatarUrl,
        birthDate: defaultBirthDate,
        weight: 70.0,
        height: 170.0,
        gender: 'Prefer not to say',
        fitnessLevel: 'Beginner',
        weeklyWorkouts: '3-4 times per week',
        workoutDuration: '30-45 minutes',
        goals: ['General health improvement'],
        equipment: ['Bodyweight'],
        hasCompletedSurvey: false,
      );

      // Сохраняем профиль
      await _profileService.updateProfile(profile);
      print('_createUserProfile: Профиль создан в базе данных');

      // Прямой запрос к базе для установки has_completed_survey=false
      await _supabase
          .from('user_profiles')
          .update({'has_completed_survey': false}).eq('id', user.id);
      print('_createUserProfile: Установлен has_completed_survey=false в базе');

      // Обновляем метаданные пользователя, указывая что опрос НЕ пройден
      await _supabase.auth.updateUser(UserAttributes(
        data: {'has_completed_survey': false, 'full_name': userName},
      ));
      print('_createUserProfile: Обновлены метаданные пользователя');

      _userProfile = profile;
      _isNewUser = true;

      print(
          '_createUserProfile: Завершено создание профиля, isNewUser=true, hasCompletedSurvey=false');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
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
        final hasCompletedSurvey = (response != null &&
            response.containsKey('has_completed_survey') &&
            response['has_completed_survey'] == true);

        debugPrint(
            'forceCheckSurveyCompletionInDatabase: Значение в базе данных has_completed_survey = ${response?['has_completed_survey']}');

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
        return false;
      }
    } catch (e) {
      debugPrint('forceCheckSurveyCompletionInDatabase: Ошибка - $e');
      return false;
    }
  }
}
