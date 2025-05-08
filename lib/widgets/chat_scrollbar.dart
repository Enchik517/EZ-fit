import 'package:flutter/material.dart';
import 'dart:async';

class ChatScrollbar extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final Color? thumbColor;
  final double thickness;
  final double? height;
  final bool showScrollToBottomButton;

  const ChatScrollbar({
    super.key,
    required this.child,
    required this.scrollController,
    this.thumbColor,
    this.thickness = 6.0,
    this.height,
    this.showScrollToBottomButton = true,
  });

  @override
  State<ChatScrollbar> createState() => _ChatScrollbarState();
}

class _ChatScrollbarState extends State<ChatScrollbar>
    with SingleTickerProviderStateMixin {
  bool _isScrolling = false;
  bool _isShowingScrollToBottom = false;
  late AnimationController _animationController;
  late Animation<double> _thumbSizeAnimation;
  Timer? _scrollTimer;

  // Значение прокрутки до конца
  final double _scrollThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);

    // Инициализация анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _thumbSizeAnimation = Tween<double>(
      begin: widget.thickness,
      end: widget.thickness * 1.4, // Немного увеличиваем при активации
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Проверяем начальную позицию скролла
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    _scrollTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    _checkScrollPosition();

    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
      _animationController.forward(); // Увеличиваем полосу прокрутки
    }

    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
        _animationController.reverse(); // Уменьшаем полосу прокрутки
      }
    });
  }

  void _checkScrollPosition() {
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    final atEnd =
        position.pixels >= position.maxScrollExtent - _scrollThreshold;

    if (_isShowingScrollToBottom != !atEnd) {
      setState(() {
        _isShowingScrollToBottom = !atEnd;
      });
    }
  }

  void _scrollToBottom() {
    if (!widget.scrollController.hasClients) return;

    widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Базовый цвет - используем цвет из виджета или из темы
    final baseColor = widget.thumbColor ?? colorScheme.primary;

    // Цвет для скроллбара в разных состояниях
    final thumbColor =
        _isScrolling ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.4);

    return Stack(
      children: [
        // Основной скроллбар с анимированной толщиной
        AnimatedBuilder(
          animation: _thumbSizeAnimation,
          builder: (context, child) {
            return RawScrollbar(
              thumbColor: thumbColor,
              thumbVisibility: true,
              thickness: _thumbSizeAnimation.value,
              radius: const Radius.circular(12),
              controller: widget.scrollController,
              child: widget.child,
            );
          },
        ),

        // Кнопка прокрутки вниз
        if (widget.showScrollToBottomButton && _isShowingScrollToBottom)
          Positioned(
            right: 16.0,
            bottom: widget.height != null ? widget.height! * 0.1 : 100.0,
            child: AnimatedOpacity(
              opacity: _isShowingScrollToBottom ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Material(
                elevation: 3.0,
                shadowColor: Colors.black26,
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _scrollToBottom,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.arrow_downward,
                      color: colorScheme.onSurfaceVariant,
                      size: 16.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ChatListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ChatListView({
    super.key,
    required this.scrollController,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ChatScrollbar(
      scrollController: scrollController,
      child: ListView(
        controller: scrollController,
        padding: padding ?? const EdgeInsets.all(8),
        shrinkWrap: true,
        children: children,
      ),
    );
  }
}

class ChatSingleChildScrollView extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;

  const ChatSingleChildScrollView({
    super.key,
    required this.scrollController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChatScrollbar(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: child,
      ),
    );
  }
}
