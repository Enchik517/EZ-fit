import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../models/chat_message.dart';
import '../services/chat_service.dart' as chat_service hide ChatMessage;
import '../services/survey_service.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/ai_workout_plan.dart';
import '../providers/workout_provider.dart';
import '../main.dart'; // Для доступа к navigatorKey
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:uuid/uuid.dart';
import '../services/chat_functions.dart';

class ChatProvider with ChangeNotifier {
  final _uuid = Uuid();
  final _supabase = Supabase.instance.client;
  final List<ChatMessage> _messages = [];
  final chat_service.ChatService _chatService;
  final SurveyService _surveyService = SurveyService();
  bool _isLoading = false;
  String? _currentText;
  Map<String, dynamic>? _lastWorkoutSuggestion;
  double? _savedScrollPosition;
  bool _isAutoScrollEnabled = true; // Флаг автоматической прокрутки
  bool _needsScrollToBottom =
      true; // Флаг, показывающий необходимость прокрутки вниз
  bool _hasInitializedMessages = false; // Флаг инициализации сообщений
  ScrollController get scrollController => _chatService.scrollController;

  ChatProvider(this._chatService) {
    _initializeSubscription();
    _chatService.scrollController.addListener(_saveScrollPosition);
    // Проверяем состояние контроллера и обновляем флаг автопрокрутки
    _checkScrollControllerState();
  }

  // Проверка состояния контроллера для корректной работы автопрокрутки
  void _checkScrollControllerState() {
    // Периодически проверяем состояние
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_chatService.scrollController.hasClients) {
        _saveScrollPosition();
      }

      // Если сообщения загружены, но нужна прокрутка
      if (_needsScrollToBottom && _hasInitializedMessages) {
        scrollToBottom(animate: true);
        _needsScrollToBottom = false;
      }

      // Продолжаем периодические проверки
      _checkScrollControllerState();
    });
  }

  void _saveScrollPosition() {
    if (!_chatService.scrollController.hasClients) return;

    try {
      _savedScrollPosition = _chatService.scrollController.position.pixels;

      // Проверяем, находится ли пользователь внизу чата
      if (_chatService.scrollController.position.pixels >=
          _chatService.scrollController.position.maxScrollExtent - 100) {
        _isAutoScrollEnabled = true;
      } else {
        _isAutoScrollEnabled = false;
      }
    } catch (e) {
      // Игнорируем ошибки позиции, которые могут возникать при перестроении виджета
      debugPrint('Error saving scroll position (safe to ignore): $e');
    }
  }

  void _restoreScrollPosition() {
    if (_savedScrollPosition == null ||
        !_chatService.scrollController.hasClients) return;

    try {
      _chatService.scrollController.jumpTo(_savedScrollPosition!);
    } catch (e) {
      debugPrint('Error restoring scroll position (safe to ignore): $e');
    }
  }

  // Улучшенный метод прокрутки с обработкой ошибок
  void scrollToBottom({Duration delay = Duration.zero, bool animate = true}) {
    Future.delayed(delay, () {
      if (!_chatService.scrollController.hasClients) {
        // Запрашиваем повторную прокрутку позже, если контроллер не готов
        _needsScrollToBottom = true;
        return;
      }

      try {
        final position = _chatService.scrollController.position;
        final target = position.maxScrollExtent;

        // Проверяем, есть ли вообще куда прокручивать
        if (target <= 0) return;

        if (animate) {
          _chatService.scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _chatService.scrollController.jumpTo(target);
        }

        // Прокрутка выполнена успешно
        _needsScrollToBottom = false;
      } catch (e) {
        // Если возникла ошибка, планируем повторную прокрутку
        _needsScrollToBottom = true;
        debugPrint('Error scrolling to bottom (safe to ignore): $e');
      }
    });
  }

  void _initializeSubscription() {
    _chatService.messagesStream.listen(
      (messages) {
        final hadMessages = _messages.isNotEmpty;
        final oldMessageCount = _messages.length;

        _messages.clear();
        _messages.addAll(messages);
        _hasInitializedMessages = true;

        // Определяем, нужно ли прокручивать вниз
        final hasNewMessages =
            !hadMessages || messages.length > oldMessageCount;

        notifyListeners();

        // Скроллим вниз с разными стратегиями в зависимости от ситуации
        if (hasNewMessages || _isAutoScrollEnabled) {
          // Прокрутка с анимацией для новых сообщений
          Future.delayed(const Duration(milliseconds: 100), () {
            scrollToBottom(animate: false);
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            scrollToBottom(animate: true);
          });
        } else if (_savedScrollPosition != null) {
          // Восстанавливаем позицию пользователя
          Future.delayed(
              const Duration(milliseconds: 100), _restoreScrollPosition);
        } else {
          // Если все остальные условия не выполнены, прокручиваем вниз
          Future.delayed(const Duration(milliseconds: 300), () {
            scrollToBottom(animate: true);
          });
        }
      },
      onError: (error) {
        debugPrint('Error in messages stream: $error');
      },
    );
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Map<String, dynamic>? get lastWorkoutSuggestion => _lastWorkoutSuggestion;

  set lastWorkoutSuggestion(Map<String, dynamic>? workout) {
    _lastWorkoutSuggestion = workout;
    notifyListeners();
  }

  String _generateMessageId() {
    return _uuid.v4();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _isLoading = true;
    _currentText = text;
    notifyListeners();

    try {
      await _chatService.sendMessage(text);

      // Включаем автоскроллинг при отправке сообщения
      _isAutoScrollEnabled = true;

      // Прокручиваем к новому сообщению с небольшой задержкой
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollToBottom(animate: true);
      });
    } catch (e) {
      _messages.add(ChatMessage(
        id: _generateMessageId(),
        userId: 'ai',
        content: 'Error: Failed to get response from AI',
        isUser: false,
        chatId: 'default',
        createdAt: DateTime.now(),
      ));
      notifyListeners();
    } finally {
      _isLoading = false;
      _currentText = null;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _chatService.clearHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> deleteMessages(List<ChatMessage> messages) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Delete messages from chat_messages table
      final messageIds = messages.map((m) => m.id).toList();
      await _supabase
          .from('chat_messages')
          .delete()
          .filter('id', 'in', messageIds)
          .eq('user_id', userId);

      // Update local state
      _messages.removeWhere((m) => messageIds.contains(m.id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting messages: $e');
    }
  }

  Future<void> sendImage(String imagePath) async {
    try {
      final imageUrl = await _chatService.sendImage(imagePath);
      await _chatService.sendMessage('Sent an image', imageUrl: imageUrl);
    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    await _chatService.saveWorkout(workout);
    _lastWorkoutSuggestion = null;
    notifyListeners();
  }

  // Метод для принудительной перезагрузки сообщений
  Future<void> reloadMessages() async {
    try {
      _needsScrollToBottom = true;
      await _chatService.reloadMessages();
    } catch (e) {
      debugPrint('Error reloading messages: $e');
    }
  }

  void dispose() {
    _chatService.dispose();
  }

  // Полная очистка состояния провайдера и установка нового сервиса
  void reset(chat_service.ChatService chatService) {
    _messages.clear();
    _isLoading = false;
    _currentText = null;
    _lastWorkoutSuggestion = null;
    _savedScrollPosition = null;
    _isAutoScrollEnabled = true;
    _needsScrollToBottom = true;
    _hasInitializedMessages = false;

    // Сначала очищаем текущий сервис
    _chatService.reset();

    // Отписываемся от старого скролл-контроллера
    _chatService.scrollController.removeListener(_saveScrollPosition);

    // Переинициализируем подписку
    _initializeSubscription();

    // Добавляем листенер к контроллеру
    _chatService.scrollController.addListener(_saveScrollPosition);

    notifyListeners();
    debugPrint('ChatProvider reset completed');
  }
}
