import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Это тестовый класс для отладки проблем с загрузкой JSON файлов
class JsonTestLoader {
  /// Пытается загрузить упражнения из JSON файла и возвращает результат
  static Future<Map<String, dynamic>> testJsonLoading() async {
    Map<String, dynamic> result = {
      'success': false,
      'assets_json_size': 0,
      'root_json_size': 0,
      'assets_json_content': '',
      'root_json_content': '',
      'assets_json_error': '',
      'root_json_error': '',
      'exercises_count': 0,
    };

    try {
      print('🧪 JsonTestLoader: Начинаем тест загрузки JSON файлов');

      // Тест 1: загрузка из assets
      try {
        final String jsonString =
            await rootBundle.loadString('assets/exercise.json');
        result['assets_json_size'] = jsonString.length;

        if (jsonString.isNotEmpty) {
          result['assets_json_content'] =
              jsonString.substring(0, math.min(100, jsonString.length));
          try {
            final List<dynamic> decoded = json.decode(jsonString);
            result['exercises_count'] = decoded.length;
            result['success'] = true;
          } catch (e) {
            result['assets_json_error'] = 'Ошибка декодирования JSON: $e';
          }
        } else {
          result['assets_json_error'] = 'Пустой файл';
        }
      } catch (e) {
        result['assets_json_error'] = 'Ошибка загрузки: $e';
      }

      // Тест 2: загрузка из корневой директории
      try {
        final String jsonString = await rootBundle.loadString('exercise.json');
        result['root_json_size'] = jsonString.length;

        if (jsonString.isNotEmpty) {
          result['root_json_content'] =
              jsonString.substring(0, math.min(100, jsonString.length));
        } else {
          result['root_json_error'] = 'Пустой файл';
        }
      } catch (e) {
        result['root_json_error'] = 'Ошибка загрузки: $e';
      }

      print('🧪 JsonTestLoader: Тест завершен, результат: $result');
      return result;
    } catch (e) {
      print('🧪 JsonTestLoader: Критическая ошибка: $e');
      result['error'] = e.toString();
      return result;
    }
  }
}
