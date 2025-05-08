import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/workout_log.dart';
import '../models/ai_workout_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/survey_service.dart';
import 'chat_functions.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/chat_message.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  final String _chatId;
  final Map<String, List<ChatMessage>> _chatMessages = {};
  Map<String, dynamic>? _lastWorkoutSuggestion;
  bool _isInitialized = false;
  final scrollController = ScrollController();

  List<Map<String, dynamic>> _savedWorkouts = [];
  Map<String, dynamic>? _userProfile;
  List<ChatMessage> _messageHistory = [];

  List<Map<String, dynamic>> get savedWorkouts => _savedWorkouts;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<ChatMessage> get messageHistory => _messageHistory;

  ChatService({String chatId = 'default'}) : _chatId = chatId {
    _initializeChat();
  }

  String get currentChatId => _chatId;
  Map<String, dynamic>? get lastWorkoutSuggestion => _lastWorkoutSuggestion;
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }

      // Очищаем старые сообщения
      _chatMessages.clear();

      // Load existing messages
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .eq('chat_id', _chatId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList();

      _chatMessages[_chatId] = messages;
      _messagesController.add(messages);

      // Scroll to bottom after loading initial messages
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      //
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .eq('chat_id', _chatId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList();

      //
      _chatMessages[_chatId] = messages;
      _messagesController.add(messages);

      // Scroll to bottom after loading messages
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  String _formatAIMessage(String message, bool isFirstMessage) {
    var formatted = message.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Список категорий эмодзи для различных типов сообщений
    final emojiCategories = {
      'greeting': ['👋', '✨', '🌟', '💫', '😊', '🤗', '👍', '🙌', '👏', '🎉'],
      'workout': ['💪', '🏋️', '🔥', '⚡', '🏃', '🤸', '🧘', '🏆', '💯', '🚀'],
      'nutrition': [
        '🥗',
        '🍎',
        '🥑',
        '🥩',
        '🍗',
        '🥦',
        '🥛',
        '🍓',
        '🍽️',
        '🥝'
      ],
      'progress': ['📈', '🎯', '🌟', '💫', '🚀', '🔝', '🏆', '🌈', '💎', '✅'],
      'motivation': ['💪', '🔥', '⚡', '✨', '💯', '🚀', '🎯', '📈', '⭐', '💎'],
      'recovery': ['🧘', '💆', '🌿', '🧠', '😴', '🌙', '⏱️', '🔄', '🌊', '🧖'],
      'profile': ['👤', '📝', '✏️', '✨', '🧩', '📊', '🔍', '🧿', '📌', '📋'],
      'system': ['🔄', '⚙️', '🔧', '📢', '🔔', '🔎', '🖥️', '📱', '⌨️', '🔌'],
      'error': ['⚠️', '❌', '🚫', '⛔', '😵', '🆘', '⭕', '🔴', '❗', '❓'],
      'success': ['✅', '👍', '🌟', '💫', '🎉', '🥳', '🏆', '🎊', '💯', '🤩'],
    };

    // Определяем тип сообщения по ключевым словам
    String messageType = 'workout'; // По умолчанию

    if (formatted.toLowerCase().contains(RegExp(r'привет|hello|hi |hey'))) {
      messageType = 'greeting';
    } else if (formatted.toLowerCase().contains(
        RegExp(r'еда|питание|калории|protein|nutrition|diet|eat|food|meal'))) {
      messageType = 'nutrition';
    } else if (formatted
        .toLowerCase()
        .contains(RegExp(r'отдых|восстановление|сон|rest|recovery|sleep'))) {
      messageType = 'recovery';
    } else if (formatted
        .toLowerCase()
        .contains(RegExp(r'прогресс|progress|improve|growth|развитие'))) {
      messageType = 'progress';
    } else if (formatted
        .toLowerCase()
        .contains(RegExp(r'мотивация|motivation|inspire|push|стимул'))) {
      messageType = 'motivation';
    }

    // Если сообщение уже начинается с эмодзи, не добавляем еще один
    if (!formatted.contains(RegExp(r'^[\p{Emoji}]', unicode: true))) {
      // Выбираем случайный эмодзи из соответствующей категории
      final emojis = emojiCategories[messageType]!;
      final random = Random();
      formatted = "${emojis[random.nextInt(emojis.length)]} $formatted";
    }

    // Делим на параграфы и вставляем эмодзи
    final paragraphs = formatted.split('\n\n');
    if (paragraphs.length > 1) {
      final random = Random();
      final emojis = emojiCategories[messageType]!;

      for (var i = 1; i < paragraphs.length; i++) {
        if (paragraphs[i].isNotEmpty &&
            !paragraphs[i].startsWith(RegExp(r'[\p{Emoji}]', unicode: true)) &&
            random.nextDouble() < 0.5) {
          // Добавляем эмодзи к некоторым параграфам
          paragraphs[i] =
              "${emojis[random.nextInt(emojis.length)]} ${paragraphs[i]}";
        }
      }
      formatted = paragraphs.join('\n\n');
    }

    // Теперь улучшаем списки с эмодзи (только если сервер не добавил их)
    if (formatted.contains(RegExp(r'^- |^\d+\. |^• ', multiLine: true))) {
      final random = Random();
      final emojis = emojiCategories[messageType]!;

      // Маркированные списки
      formatted = formatted.replaceAllMapped(RegExp(r'(^|\n)(- |• )([^-\n•]+)'),
          (match) {
        if (random.nextDouble() < 0.5 &&
            !match.group(3)!.contains(RegExp(r'[\p{Emoji}]', unicode: true))) {
          return "${match.group(1)!}${match.group(2)!}${emojis[random.nextInt(emojis.length)]} ${match.group(3)!}";
        }
        return match.group(0)!;
      });

      // Нумерованные списки
      formatted = formatted
          .replaceAllMapped(RegExp(r'(^|\n)(\d+\. )([^\.\n]+)'), (match) {
        if (random.nextDouble() < 0.5 &&
            !match.group(3)!.contains(RegExp(r'[\p{Emoji}]', unicode: true))) {
          return "${match.group(1)!}${match.group(2)!}${emojis[random.nextInt(emojis.length)]} ${match.group(3)!}";
        }
        return match.group(0)!;
      });
    }

    // Clean up multiple asterisks and format bold text properly
    formatted = formatted
        .replaceAll(
            RegExp(r'\*{2,}'), '**') // Replace multiple asterisks with double
        .replaceAll(
            RegExp(r'(\*\*\s*\*\*|\*\*\s+\*\*)'), ' ') // Remove empty bold tags
        .replaceAll(RegExp(r'\s+'), ' '); // Clean up multiple spaces

    // Format numbers and important terms as bold if not already formatted
    if (!formatted.contains('**')) {
      formatted = formatted.replaceAllMapped(
          RegExp(
              r'\b(weight|gain|loss|bulk|cut|workout|strength|cardio|form|muscle|fitness|goal|progress|training|exercise|calories|protein|sets|reps|\d+(?:g|lbs|kg|kcal)?)\b'),
          (match) {
        var term = match.group(0)!;
        return term.contains('**') ? term : '**$term**';
      });
    }

    return formatted;
  }

  Future<void> _sendMessage(String message, {String action = 'chat'}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }

      // Определяем режим генератора тренировок
      // Временно отключаем генерацию тренировок
      final isWorkoutGenerator = false; // Отключаем эту функциональность
      if (message.startsWith('WORKOUT_GENERATOR:')) {
        message = message.replaceFirst('WORKOUT_GENERATOR:', '').trim();
        // Не меняем action, чтобы не запускать генератор тренировок
      }

      // Get AI response first
      // Загружаем профиль только если это нужно для персонализации
      Map<String, dynamic>? userProfile;
      if (isWorkoutGenerator ||
          action == 'profile_update' ||
          message.toLowerCase().contains('workout') ||
          message.toLowerCase().contains('exercise') ||
          message.toLowerCase().contains('training')) {
        final userProfileResponse =
            await _supabase.from('user_profiles').select().eq('id', userId);

        userProfile =
            userProfileResponse.isNotEmpty ? userProfileResponse[0] : null;

        if (userProfile == null) {
          throw Exception(
              'Please complete your profile setup before requesting workout-related advice');
        }
      }

      // Проверяем, есть ли уже сообщения в чате
      final existingMessages = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('user_id', userId)
          .eq('chat_id', _chatId)
          .limit(1);

      final isVeryFirstMessage = existingMessages.isEmpty;

      final response = await _supabase.functions.invoke(
        'chat',
        body: {
          'message': message,
          'action': action,
          'is_first_message': isVeryFirstMessage,
          'profile': userProfile != null
              ? {
                  ...userProfile,
                  'current_stats': {
                    'weight': userProfile['weight'],
                    'height': userProfile['height'],
                    'gender': userProfile['gender'],
                    'age': userProfile['age'],
                    'activity_level': userProfile['activity_level'],
                    'fitness_level': userProfile['fitness_level'],
                  },
                  'preferences': {
                    'goals': userProfile['goals'],
                    'equipment': userProfile['equipment'],
                    'injuries': userProfile['injuries'],
                    'weekly_workouts': userProfile['weekly_workouts'],
                    'workout_duration': userProfile['workout_duration'],
                  },
                  'history': await _getRecentMessages(userId),
                }
              : null,
        },
        headers: {
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw 'Error: ${response.status} - ${response.data?.toString() ?? "Unknown error"}';
      }

      final data = response.data;
      // Обработка и ограничение размера сообщения
      String aiMessage = data['message'] as String;

      // Удаляем JSON структуры из ответа
      aiMessage = _removeJsonStructures(aiMessage);

      // Ограничиваем длину сообщения
      aiMessage = _limitMessageSize(aiMessage);

      // Форматируем сообщение
      aiMessage = _formatAIMessage(aiMessage, isVeryFirstMessage);

      // Save both messages in a single transaction
      final messages = [];

      // Save user message if not in workout generator mode
      if (!isWorkoutGenerator) {
        messages.add({
          'user_id': userId,
          'content': message,
          'is_user': true,
          'image_url': null,
          'chat_id': _chatId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Save AI response
      messages.add({
        'user_id': userId,
        'content': aiMessage,
        'is_user': false,
        'image_url': null,
        'chat_id': _chatId,
        'created_at': DateTime.now().toIso8601String(),
      });

      final responses =
          await _supabase.from('chat_messages').insert(messages).select();

      final chatMessages =
          (responses as List).map((msg) => ChatMessage.fromJson(msg)).toList();

      final currentMessages = _chatMessages[_chatId] ?? [];
      _chatMessages[_chatId] = [...currentMessages, ...chatMessages];
      _messagesController.add(_chatMessages[_chatId]!);

      // Update context from server
      if (data['context'] != null) {
        final context = data['context'];
        if (context['workouts'] != null) {
          _savedWorkouts = List<Map<String, dynamic>>.from(context['workouts']);
        }
        if (context['profile'] != null) {
          _userProfile = Map<String, dynamic>.from(context['profile']);
        }
        if (context['messageHistory'] != null) {
          _messageHistory = (context['messageHistory'] as List)
              .map((m) => ChatMessage(
                    id: const Uuid().v4(),
                    userId: userId,
                    chatId: _chatId,
                    content: m['content'],
                    isUser: m['role'] == 'user',
                    createdAt: DateTime.now(),
                  ))
              .toList();
        }
      }

      // Scroll to bottom with improved animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic, // Более плавная анимация
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Новая функция для удаления JSON структур из ответа
  String _removeJsonStructures(String message) {
    // Ищем JSON структуры с помощью регулярных выражений
    final jsonPattern =
        RegExp(r'```(?:json)?\s*\{\s*".*?"\s*:.*?\}\s*```', dotAll: true);

    // Заменяем JSON структуры на более читаемый текст
    return message.replaceAllMapped(jsonPattern, (match) {
      // Если мы хотим полностью удалить JSON
      return "Я могу составить для вас план тренировки. Просто скажите, что именно вы хотели бы тренировать.";
    });
  }

  // Новая функция для ограничения размера сообщения
  String _limitMessageSize(String message) {
    // Если сообщение слишком длинное, обрезаем его и добавляем многоточие
    const int maxLength = 500; // Максимальная длина сообщения

    if (message.length > maxLength) {
      // Делим на параграфы и берем первые несколько
      final paragraphs = message.split('\n\n');

      if (paragraphs.length > 3) {
        // Берем только первые 3 параграфа, чтобы сообщение было компактным
        message = paragraphs.take(3).join('\n\n');

        // Если все еще слишком длинное, обрезаем
        if (message.length > maxLength) {
          message = message.substring(0, maxLength);
          // Находим последнюю точку для "красивого" обрезания
          final lastDot = message.lastIndexOf('.');
          if (lastDot > maxLength * 0.8) {
            // Если точка достаточно близко к концу
            message = message.substring(0, lastDot + 1);
          }
        }
      } else {
        // Если параграфов мало, просто обрезаем
        message = message.substring(0, maxLength);
        final lastDot = message.lastIndexOf('.');
        if (lastDot > maxLength * 0.8) {
          message = message.substring(0, lastDot + 1);
        }
      }
    }

    return message;
  }

  Map<String, dynamic>? _extractWorkoutJson(String content) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = content.substring(jsonStart, jsonEnd + 1);
        final json = jsonDecode(jsonStr);

        if (json is Map<String, dynamic> &&
            json.containsKey('name') &&
            json.containsKey('exercises')) {
          // Преобразуем формат упражнений
          final exercises = (json['exercises'] as List).map((e) {
            if (e is Map<String, dynamic>) {
              return {
                'name': e['name'],
                'sets': e['sets'],
                'reps': e['reps'],
                'target_muscle_group': e['targetMuscleGroup'] ??
                    e['target_muscle_group'] ??
                    'Full Body',
                'equipment': e['equipment'] ?? 'none'
              };
            }
            return e;
          }).toList();

          // Возвращаем только поля, которые есть в схеме базы данных
          final workoutData = {
            'name': json['name'],
            'description': json['description'] ?? 'AI Generated Workout',
            'focus': json['focus'] ?? json['name'],
            'difficulty': json['difficulty'] ?? 'intermediate',
            'duration': json['duration'] ?? 45,
            'category': 'ai_generated',
            'equipment': json['equipment'] ?? ['none'],
            'exercises': exercises,
            'target_muscles': json['target_muscles'] ??
                json['targetMuscles'] ??
                [json['focus'] ?? 'Full Body']
          };

          // Удаляем поля, которых нет в схеме
          workoutData.remove('warmUp');
          workoutData.remove('coolDown');
          workoutData.remove('totalDuration');
          workoutData.remove('exerciseTime');
          workoutData.remove('restBetweenSets');
          workoutData.remove('restBetweenExercises');

          return workoutData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting workout JSON: $e');
      return null;
    }
  }

  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      //
      // Преобразуем упражнения в правильный формат с сохранением superSetId
      final exercises = (workout['exercises'] as List).map((e) {
        final superSetId = e['superSetId'] ?? e['super_set_id'];
        return Exercise.basic(
          name: e['name'],
          targetMuscleGroup:
              e['targetMuscleGroup'] ?? e['target_muscle_group'] ?? 'Full Body',
          equipment: e['equipment'],
          sets: e['sets']?.toString() ?? "4",
          reps: e['reps']?.toString() ?? "12",
          difficulty:
              e['difficulty'] ?? workout['difficulty'] ?? 'Intermediate',
          description: e['description'] ?? e['notes'] ?? '',
          superSetId: superSetId,
        );
      }).toList();

      // Создаем полноценный объект тренировки
      final fullWorkout = Workout(
        id: const Uuid().v4(),
        name: workout['name'],
        description: workout['description'] ?? 'AI Generated Workout',
        exercises: exercises,
        duration: workout['duration'] ?? 45,
        difficulty: workout['difficulty'] ?? 'intermediate',
        equipment: List<String>.from(workout['equipment'] ?? []),
        targetMuscles: List<String>.from(workout['target_muscles'] ??
            workout['targetMuscles'] ??
            [workout['focus'] ?? 'Full Body']),
        focus: workout['focus'] ?? workout['name'],
        isAIGenerated: true,
        isFavorite: true,
        createdAt: DateTime.now(),
        warmUp: workout['warmUp'] ?? '',
        coolDown: workout['coolDown'] ?? '',
        totalDuration: Duration(minutes: workout['totalDuration'] ?? 60),
        exerciseTime: Duration(seconds: workout['exerciseTime'] ?? 45),
        restBetweenSets: Duration(seconds: workout['restBetweenSets'] ?? 30),
        restBetweenExercises:
            Duration(minutes: workout['restBetweenExercises'] ?? 1),
        instructions: workout['instructions'],
        tips:
            workout['tips'] != null ? List<String>.from(workout['tips']) : null,
      );

      // Преобразуем в формат для сохранения
      final workoutData = {
        'user_id': userId,
        'name': fullWorkout.name,
        'description': fullWorkout.description,
        'exercises': fullWorkout.exercises
            .map((e) => {
                  'name': e.name,
                  'description': e.description,
                  'equipment': e.equipment,
                  'sets': e.sets,
                  'reps': e.reps,
                  'target_muscle_group': e.targetMuscleGroup,
                  'difficulty': e.difficulty,
                  'super_set_id': e.superSetId,
                  'video_url': e.videoUrl,
                  'instructions': e.instructions,
                  'common_mistakes': e.commonMistakes,
                  'modifications': e.modifications,
                  'exercise_time': e.exerciseTime.inSeconds,
                  'rest_time': e.restTime.inSeconds,
                })
            .toList(),
        'difficulty': fullWorkout.difficulty,
        'equipment': fullWorkout.equipment,
        'target_muscles': fullWorkout.targetMuscles,
        'focus': fullWorkout.focus,
        'duration': fullWorkout.duration,
        'created_at': fullWorkout.createdAt?.toIso8601String(),
        'is_favorite': true,
        'is_ai_generated': true,
        'category': workout['category'] ?? 'custom',
        'warm_up': fullWorkout.warmUp,
        'cool_down': fullWorkout.coolDown,
        'total_duration': fullWorkout.totalDuration.inMinutes,
        'exercise_time': fullWorkout.exerciseTime.inSeconds,
        'rest_between_sets': fullWorkout.restBetweenSets.inSeconds,
        'rest_between_exercises': fullWorkout.restBetweenExercises.inMinutes,
        'instructions': fullWorkout.instructions,
        'tips': fullWorkout.tips,
      };

      // Сохраняем в базу данных
      final response =
          await _supabase.from('workouts').insert(workoutData).select();

      final savedWorkout = response.isNotEmpty ? response[0] : workoutData;

      // Обновляем локальный список сохраненных тренировок
      _savedWorkouts.insert(0, savedWorkout);
    } catch (e) {
      debugPrint('Error saving workout: $e');
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', userId)
          .eq('chat_id', _chatId);

      _chatMessages[_chatId]?.clear();
      _messagesController.add([]);
    } catch (e) {
      debugPrint('Error clearing history: $e');
      rethrow;
    }
  }

  Future<void> deleteMessages(List<ChatMessage> messages) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final messageIds = messages.map((m) => m.id).toList();
      await _supabase
          .from('chat_messages')
          .delete()
          .filter('id', 'in', messageIds)
          .eq('user_id', userId);

      _chatMessages[_chatId]?.removeWhere((m) => messageIds.contains(m.id));
      _messagesController.add(_chatMessages[_chatId] ?? []);
    } catch (e) {
      debugPrint('Error deleting messages: $e');
      rethrow;
    }
  }

  Future<String> sendImage(String imagePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final file = File(imagePath);
      final fileExt = path.extension(imagePath);
      final fileName = '${DateTime.now().toIso8601String()}$fileExt';

      await _supabase.storage
          .from('chat_images')
          .uploadBinary('$userId/$fileName', await file.readAsBytes());

      return _supabase.storage
          .from('chat_images')
          .getPublicUrl('$userId/$fileName');
    } catch (e) {
      debugPrint('Error sending image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> getChatsList() async {
    return ['default'];
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void dispose() {
    _messagesController.close();
    scrollController.dispose();
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    _userProfile = profile;
    await _sendMessage('Profile updated', action: 'profile_update');
  }

  Future<void> clearContext() async {
    await _sendMessage('', action: 'clear_history');
    _savedWorkouts = [];
    _userProfile = null;
    _messageHistory = [];
  }

  Future<void> sendMessage(String text, {String? imageUrl}) async {
    await _sendMessage(text);
  }

  Future<List<Map<String, dynamic>>> _getRecentMessages(String userId) async {
    try {
      final messages = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      debugPrint('Error getting recent messages: $e');
      return [];
    }
  }

  // Добавляем метод для перезагрузки сообщений
  Future<void> reloadMessages() async {
    _isInitialized = false; // Сбрасываем флаг инициализации
    await _initializeChat(); // Повторно инициализируем чат
  }

  // Метод для полной очистки кэша сообщений при смене пользователя
  void reset() {
    _isInitialized = false;
    _chatMessages.clear();
    _lastWorkoutSuggestion = null;
    _savedWorkouts = [];
    _userProfile = null;
    _messageHistory = [];
    _messagesController.add([]);
    debugPrint('ChatService reset completed');
  }
}
