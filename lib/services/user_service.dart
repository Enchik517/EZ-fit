import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Сервис для работы с данными пользователя
class UserService {
  static const String _userKey = 'user_data';

  /// Получить текущего пользователя из хранилища
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) {
        // Если пользователя нет, создаем пустого по умолчанию
        final newUser = User(
          id: 'local_user',
          name: 'Пользователь',
          favoriteExercises: [],
        );
        await _saveUser(newUser);
        return newUser;
      }

      return User.fromJson(json.decode(userJson));
    } catch (e) {
      print('❌ Ошибка при получении пользователя: $e');
      return null;
    }
  }

  /// Обновить список избранных упражнений
  static Future<bool> updateFavoriteExercises(List<String> exerciseIds) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final updatedUser = user.copyWith(favoriteExercises: exerciseIds);
      return await _saveUser(updatedUser);
    } catch (e) {
      print('❌ Ошибка при обновлении избранных упражнений: $e');
      return false;
    }
  }

  /// Добавить упражнение в избранное
  static Future<bool> addToFavorites(String exerciseId) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final favorites = user.favoriteExercises?.toList() ?? [];
      if (!favorites.contains(exerciseId)) {
        favorites.add(exerciseId);

        final updatedUser = user.copyWith(favoriteExercises: favorites);
        return await _saveUser(updatedUser);
      }

      return true; // Уже в избранном
    } catch (e) {
      print('❌ Ошибка при добавлении в избранное: $e');
      return false;
    }
  }

  /// Удалить упражнение из избранного
  static Future<bool> removeFromFavorites(String exerciseId) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final favorites = user.favoriteExercises?.toList() ?? [];
      if (favorites.contains(exerciseId)) {
        favorites.remove(exerciseId);

        final updatedUser = user.copyWith(favoriteExercises: favorites);
        return await _saveUser(updatedUser);
      }

      return true; // Уже не в избранном
    } catch (e) {
      print('❌ Ошибка при удалении из избранного: $e');
      return false;
    }
  }

  /// Сохранить пользователя в хранилище
  static Future<bool> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userKey, json.encode(user.toJson()));
    } catch (e) {
      print('❌ Ошибка при сохранении пользователя: $e');
      return false;
    }
  }

  /// Очистить данные пользователя
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_userKey);
    } catch (e) {
      print('❌ Ошибка при очистке данных пользователя: $e');
      return false;
    }
  }
}
