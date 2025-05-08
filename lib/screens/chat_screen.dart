import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../widgets/ai_workout_plan_widget.dart';
import '../services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/chat_scrollbar.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/pulsating_dots_loader.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _textController = TextEditingController();
  bool _isLoading = false;
  // Режим генерации тренировок всегда выключен
  final bool _isWorkoutMode = false;
  bool _isInitialized = false;
  int _messageCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Добавляем наблюдатель жизненного цикла

    // Добавляем несколько попыток прокрутки с различными задержками
    // Первая попытка - после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });

    // Серия отложенных прокруток для надежности
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToBottom(animate: false);
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _scrollToBottom(animate: true);
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      _scrollToBottom(animate: true);
      _isInitialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Получаем провайдер и подписываемся на изменения количества сообщений
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addListener(_onChatUpdated);

    // Получаем количество сообщений для отслеживания изменений
    _messageCount = chatProvider.messages.length;

    // Прокручиваем после изменения зависимостей (часто происходит при переключении вкладок)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // При возвращении в приложение после свертывания прокручиваем вниз
    if (state == AppLifecycleState.resumed) {
      _reloadMessages(); // Перезагружаем сообщения

      // Серия прокруток с разной задержкой для повышения надежности
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom(animate: false);
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        _scrollToBottom(animate: true);
      });
    }
  }

  void _onChatUpdated() {
    // Вызывается при обновлении провайдера чата
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Проверяем, добавились ли новые сообщения
    if (chatProvider.messages.length != _messageCount) {
      _messageCount = chatProvider.messages.length;

      // Если сообщений стало больше, прокручиваем вниз
      if (_messageCount > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom(animate: false);
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom(animate: true);
        });
      }
    }
  }

  // Улучшенная прокрутка к последнему сообщению с обработкой ошибок
  void _scrollToBottom({bool animate = true}) {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (!chatProvider.scrollController.hasClients) return;
      if (chatProvider.messages.isEmpty) return;

      final position = chatProvider.scrollController.position;

      // Сначала проверяем, есть ли вообще куда скроллить
      if (position.maxScrollExtent <= 0) return;

      if (animate) {
        chatProvider.scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        chatProvider.scrollController.jumpTo(position.maxScrollExtent);
      }
    } catch (e) {
      // Игнорируем ошибки прокрутки, которые могут возникнуть
      // если контроллер не полностью инициализирован
      debugPrint('Scroll error (safe to ignore): $e');
    }
  }

  // Метод для принудительной перезагрузки сообщений
  void _reloadMessages() {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.reloadMessages();
    } catch (e) {
      debugPrint('Error reloading messages: $e');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Этот метод вызывается при горячей перезагрузке во время разработки
    // и полезен для отладки проблем со скроллингом
    _reloadMessages();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scrollToBottom(animate: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = chatProvider.messages;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isWorkoutMode ? 'Workout Generator' : 'AI Coach',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              _isWorkoutMode
                  ? 'Create personalized workouts'
                  : 'Your personal fitness assistant',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // Временно скрываем кнопку переключения режима
          /*
          IconButton(
            icon: Icon(
              _isWorkoutMode ? Icons.fitness_center : Icons.chat_bubble_outline,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isWorkoutMode = !_isWorkoutMode;
              });
              if (_isWorkoutMode) {
                _textController.text = 'Create a workout for ';
              } else {
                _textController.clear();
              }
            },
          ),
          */
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Text('Clear history'),
                  ],
                ),
                onTap: () => _clearHistory(chatProvider),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Обновляем состояние, когда пользователь сам скроллит
                    if (notification is ScrollUpdateNotification &&
                        notification.depth == 0 &&
                        notification.dragDetails != null) {
                      _isInitialized = true;
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      ChatScrollbar(
                        scrollController: chatProvider.scrollController,
                        thumbColor: theme.colorScheme.primary.withOpacity(0.6),
                        thickness: 5.0,
                        showScrollToBottomButton: true,
                        height: MediaQuery.of(context).size.height,
                        child: ListView.builder(
                          controller: chatProvider.scrollController,
                          reverse: false, // важно для правильной прокрутки вниз
                          padding: EdgeInsets.fromLTRB(
                              12, 8, 12, _isLoading ? 80 : 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return ChatMessageWidget(
                              key: ValueKey(message.id),
                              message: message,
                              onDelete: (msg) async {
                                await chatProvider.deleteMessages([msg]);
                              },
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: PulsatingDotsLoader(
                                color: theme.colorScheme.primary,
                                dotsCount: 4,
                                dotsSize: 8,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 80),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Временно скрываем кнопку камеры
                  /*
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: _isWorkoutMode
                            ? theme.colorScheme.onSurface.withOpacity(0.3)
                            : theme.colorScheme.primary,
                      ),
                      onPressed: _isWorkoutMode
                          ? null
                          : () => _takePicture(chatProvider),
                    ),
                  ),
                  */
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: _isWorkoutMode
                              ? 'Describe your ideal workout...'
                              : 'Ask me anything about fitness...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        onSubmitted: (_) => _sendMessage(chatProvider),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => _sendMessage(chatProvider),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _textController.clear();
    });

    try {
      // Всегда используем обычный режим чата
      await chatProvider.sendMessage(text);

      // Прокручиваем после отправки сообщения
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToBottom(animate: true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takePicture(ChatProvider chatProvider) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) return;

      setState(() => _isLoading = true);

      await chatProvider.sendImage(image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearHistory(ChatProvider chatProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await chatProvider.clearHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.removeListener(_onChatUpdated);
    _textController.dispose();
    super.dispose();
  }
}
