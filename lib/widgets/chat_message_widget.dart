import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final Function(ChatMessage) onDelete;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _isSelected = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.message.isUser
          ? const Offset(0.3, 0.0)
          : const Offset(-0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Запускаем анимацию
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.message.content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Message copied to clipboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 300,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              widget.onDelete(widget.message);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;
    final isUser = message.isUser;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelected = true;
            });
            _showOptions();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser)
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            )
                          ],
                          border: isUser
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.1),
                                  width: 1,
                                ),
                        ),
                        child: MarkdownBody(
                          data: message.content ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontSize: 16,
                            ),
                            strong: TextStyle(
                              color: isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            em: TextStyle(
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.9)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              //launchUrl(Uri.parse(href));
                            }
                          },
                        ),
                      ),
                    ),
                    if (isUser) const SizedBox(width: 8),
                  ],
                ),
                if (!isUser)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 40.0, right: 8.0),
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
          return json;
        }
      }
    } catch (e) {
      debugPrint('Ошибка при извлечении JSON тренировки: $e');
    }
    return null;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
