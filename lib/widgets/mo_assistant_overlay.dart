import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:order_tracker/models/mo_assistant_message.dart';
import 'package:order_tracker/services/mo_assistant_service.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/mo_assistant_route_guide.dart';

class MoAssistantOverlay extends StatefulWidget {
  const MoAssistantOverlay({
    super.key,
    this.currentRouteName,
    this.embedded = false,
  });

  final String? currentRouteName;
  final bool embedded;

  @override
  State<MoAssistantOverlay> createState() => _MoAssistantOverlayState();
}

class _MoAssistantOverlayState extends State<MoAssistantOverlay> {
  static const double _launcherSize = 76;
  static const double _launcherMargin = 16;
  static const double _panelGap = 12;

  static const List<String> _quickPrompts = <String>[
    '\u0643\u064a\u0641 \u0623\u0639\u0645\u0644 \u0637\u0644\u0628\u064b\u0627 \u062c\u062f\u064a\u062f\u064b\u0627\u061f',
    '\u0623\u064a\u0646 \u0623\u062a\u0627\u0628\u0639 \u0627\u0644\u0645\u0647\u0627\u0645\u061f',
    '\u0642\u0644 \u0644\u064a \u0645\u0639\u0644\u0648\u0645\u0629 \u0645\u0641\u064a\u062f\u0629 \u062e\u0627\u0631\u062c \u0627\u0644\u0634\u063a\u0644',
    '\u0645\u064a\u0646 \u0637\u0648\u0631 \u0627\u0644\u0646\u0638\u0627\u0645\u061f',
  ];
  static const List<String> _welcomeSuggestions = <String>[
    '\u{1F9ED} \u0645\u0627\u0630\u0627 \u0623\u0641\u0639\u0644 \u0641\u064a \u0647\u0630\u0647 \u0627\u0644\u0634\u0627\u0634\u0629\u061f',
    '\u{1F4E6} \u0643\u064a\u0641 \u0623\u0639\u0645\u0644 \u0637\u0644\u0628\u064b\u0627 \u062c\u062f\u064a\u062f\u064b\u0627\u061f',
    '\u{1F6E0}\u{FE0F} \u0639\u0646\u062f\u064a \u0645\u0634\u0643\u0644\u0629 \u0641\u064a \u0627\u0644\u0646\u0638\u0627\u0645',
    '\u{1F30D} \u0642\u0644 \u0644\u064a \u0645\u0639\u0644\u0648\u0645\u0629 \u0645\u0641\u064a\u062f\u0629 \u062e\u0627\u0631\u062c \u0627\u0644\u0634\u063a\u0644',
  ];
  static const List<String> _generalFollowUpSuggestions = <String>[
    '\u2728 \u0627\u062e\u062a\u0635\u0631\u0647\u0627 \u0644\u064a \u0623\u0643\u062b\u0631',
    '\u{1F4DA} \u0623\u0639\u0637\u0646\u064a \u0645\u062b\u0627\u0644\u064b\u0627 \u0628\u0633\u064a\u0637\u064b\u0627',
    '\u{1F30D} \u0642\u0644 \u0644\u064a \u0645\u0639\u0644\u0648\u0645\u0629 \u0645\u0641\u064a\u062f\u0629 \u062e\u0627\u0631\u062c \u0627\u0644\u0634\u063a\u0644',
    '\u2753 \u0645\u0627 \u0623\u0647\u0645 \u0646\u0642\u0637\u0629 \u064a\u062c\u0628 \u0623\u0646 \u0623\u0639\u0631\u0641\u0647\u0627\u061f',
  ];
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
    unicode: true,
  );

  final MoAssistantService _service = MoAssistantService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<MoAssistantMessage> _messages = <MoAssistantMessage>[];

  bool _isOpen = false;
  bool _isSending = false;
  double? _launcherLeft;
  double? _launcherTop;
  double? _panelWidthOverride;
  double? _panelHeightOverride;
  Offset? _dragTouchOffset;
  Offset? _resizeStartGlobalPosition;
  double? _resizeStartWidth;
  double? _resizeStartHeight;

  @override
  void initState() {
    super.initState();
    _messages.add(
      MoAssistantMessage.assistant(
        '\u0623\u0647\u0644\u064b\u0627 \u{1F44B} \u0623\u0646\u0627 Mo\u060c \u0645\u0631\u0634\u062f\u0643 \u0627\u0644\u0630\u0643\u064a \u062f\u0627\u062e\u0644 \u0627\u0644\u0646\u0638\u0627\u0645 \u{1F916}\n'
        '\u0623\u0642\u062f\u0631 \u0623\u0633\u0627\u0639\u062f\u0643 \u0641\u064a \u062e\u0637\u0648\u0627\u062a \u0627\u0644\u0646\u0638\u0627\u0645 \u0635\u0641\u062d\u0629 \u0628\u0635\u0641\u062d\u0629\u060c \u0648\u0623\u062c\u0627\u0648\u0628\u0643 \u0623\u064a\u0636\u064b\u0627 \u0639\u0644\u0649 \u0627\u0644\u0623\u0633\u0626\u0644\u0629 \u0627\u0644\u0639\u0627\u0645\u0629 \u0648\u0627\u0644\u062e\u0627\u0631\u062c\u064a\u0629 \u0628\u0634\u0643\u0644 \u0637\u0628\u064a\u0639\u064a \u0648\u0645\u0645\u062a\u0639 \u2728',
        suggestions: _welcomeSuggestions,
      ),
    );
  }

  @override
  void dispose() {
    _service.cancelActiveRequest();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        _focusNode.requestFocus();
        _scrollToBottom(jump: true);
      });
    }
  }

  void _closePanel() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
  }

  void _cancelSending() {
    if (!_isSending) return;

    _service.cancelActiveRequest();
    setState(() {
      _isSending = false;
      _messages.add(
        MoAssistantMessage.assistant('أوقفت الرد الحالي كما طلبت ⏹️🙂'),
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? preset]) async {
    if (_isSending) return;

    final rawText = preset ?? _inputController.text;
    final text = rawText.trim();
    if (text.isEmpty) return;

    final historyBeforeSend = List<MoAssistantMessage>.from(_messages);

    setState(() {
      _messages.add(MoAssistantMessage.user(text));
      _inputController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        message: text,
        history: historyBeforeSend,
        currentRoute: widget.currentRouteName,
      );

      if (!mounted) return;
      final decoratedReply = _decorateAssistantReply(reply, userQuestion: text);
      setState(() {
        _messages.add(
          MoAssistantMessage.assistant(
            decoratedReply,
            suggestions: _buildFollowUpSuggestions(
              userQuestion: text,
              replyText: decoratedReply,
            ),
          ),
        );
      });
    } on MoAssistantRequestCancelled {
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MoAssistantMessage.assistant(
            'حاليًا ما قدرت أوصل إلى Mo كما يجب 😕\n${error.toString().replaceFirst('Exception: ', '')}',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent + 80;
      if (jump) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  double _defaultPanelWidth(MediaQueryData media) {
    final width = media.size.width < 360
        ? media.size.width - 20
        : math.min(300.0, media.size.width - 24);
    return width.clamp(_panelMinWidth(media), _panelMaxWidth(media)).toDouble();
  }

  double _defaultPanelHeight(MediaQueryData media) {
    final height = math.min(media.size.height * 0.76, 560.0);
    return height
        .clamp(_panelMinHeight(media), _panelMaxHeight(media))
        .toDouble();
  }

  double _panelMinWidth(MediaQueryData media) {
    final maxWidth = _panelMaxWidth(media);
    return math.min(260.0, maxWidth);
  }

  double _panelMaxWidth(MediaQueryData media) {
    return math.max(190.0, media.size.width - 20);
  }

  double _panelMinHeight(MediaQueryData media) {
    final maxHeight = _panelMaxHeight(media);
    return math.min(320.0, maxHeight);
  }

  double _panelMaxHeight(MediaQueryData media) {
    final availableHeight =
        media.size.height - media.padding.top - media.viewInsets.bottom - 16;
    return math.max(280.0, math.min(640.0, availableHeight));
  }

  double _clampLauncherLeft(double left, Size size) {
    final maxLeft = math.max(
      _launcherMargin,
      size.width - _launcherSize - _launcherMargin,
    );
    return left.clamp(_launcherMargin, maxLeft).toDouble();
  }

  double _clampLauncherTop(
    double top,
    Size size,
    EdgeInsets padding,
    double bottomInset,
  ) {
    final minTop = padding.top + 8;
    final maxTop = math.max(minTop, size.height - _launcherSize - bottomInset);
    return top.clamp(minTop, maxTop).toDouble();
  }

  void _updateLauncherFromGlobal({
    required Offset globalPosition,
    required Size size,
    required EdgeInsets padding,
    required double bottomInset,
  }) {
    final touchOffset =
        _dragTouchOffset ?? const Offset(_launcherSize / 2, _launcherSize / 2);

    _launcherLeft = _clampLauncherLeft(
      globalPosition.dx - touchOffset.dx,
      size,
    );
    _launcherTop = _clampLauncherTop(
      globalPosition.dy - touchOffset.dy,
      size,
      padding,
      bottomInset,
    );
  }

  void _startPanelResize(
    DragStartDetails details, {
    required double currentWidth,
    required double currentHeight,
  }) {
    _resizeStartGlobalPosition = details.globalPosition;
    _resizeStartWidth = currentWidth;
    _resizeStartHeight = currentHeight;
  }

  void _updatePanelResize(
    DragUpdateDetails details, {
    required double minWidth,
    required double maxWidth,
    required double minHeight,
    required double maxHeight,
  }) {
    if (_resizeStartGlobalPosition == null ||
        _resizeStartWidth == null ||
        _resizeStartHeight == null) {
      return;
    }

    final delta = details.globalPosition - _resizeStartGlobalPosition!;
    final nextWidth = (_resizeStartWidth! - delta.dx)
        .clamp(minWidth, maxWidth)
        .toDouble();
    final nextHeight = (_resizeStartHeight! - delta.dy)
        .clamp(minHeight, maxHeight)
        .toDouble();

    setState(() {
      _panelWidthOverride = nextWidth;
      _panelHeightOverride = nextHeight;
    });
  }

  void _stopPanelResize() {
    _resizeStartGlobalPosition = null;
    _resizeStartWidth = null;
    _resizeStartHeight = null;
  }

  Widget _buildLauncherButton() {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: _launcherSize,
        height: _launcherSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.appBarWaterDeep,
              AppColors.appBarWaterMid,
              AppColors.appBarWaterBright,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.appBarWaterBright.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF68F6C9),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF68F6C9).withValues(alpha: 0.75),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
                  key: ValueKey<bool>(_isOpen),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Text(
                'Mo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required double currentWidth,
    required double currentHeight,
    required double minWidth,
    required double maxWidth,
    required double minHeight,
    required double maxHeight,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) {
          _startPanelResize(
            details,
            currentWidth: currentWidth,
            currentHeight: currentHeight,
          );
        },
        onPanUpdate: (details) {
          _updatePanelResize(
            details,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
          );
        },
        onPanEnd: (_) => _stopPanelResize(),
        onPanCancel: _stopPanelResize,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          alignment: Alignment.center,
          child: const RotatedBox(
            quarterTurns: 1,
            child: Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeForMatching(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[\u0623\u0625\u0622]'), '\u0627')
        .replaceAll('\u0649', '\u064a')
        .replaceAll('\u0629', '\u0647')
        .replaceAll(RegExp('[^a-z0-9\u0621-\u064A]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsAny(String source, Iterable<String> patterns) {
    final normalizedSource = _normalizeForMatching(source);
    return patterns.any(
      (pattern) => normalizedSource.contains(_normalizeForMatching(pattern)),
    );
  }

  bool _containsLettersOrDigits(String value) {
    return RegExp('[A-Za-z0-9\u0621-\u064A]').hasMatch(value);
  }

  bool _containsEmoji(String value) => _emojiPattern.hasMatch(value);

  String _pickReplyEmoji({String? userQuestion, required String replyText}) {
    final normalized = _normalizeForMatching(
      '${userQuestion ?? ''} $replyText',
    );

    if (_containsAny(normalized, const <String>[
      '\u0645\u0634\u0643\u0644\u0629',
      '\u062e\u0637\u0623',
      '\u062a\u0639\u0630\u0631',
      '\u0641\u0634\u0644',
      '\u0635\u0644\u0627\u062d\u064a\u0629',
    ])) {
      return '\u{1F6E0}\u{FE0F}';
    }
    if (_containsAny(normalized, const <String>[
      '\u0637\u0644\u0628',
      '\u0627\u0644\u0637\u0644\u0628\u0627\u062a',
      'order',
    ])) {
      return '\u{1F4E6}';
    }
    if (_containsAny(normalized, const <String>[
      '\u0645\u0647\u0645\u0629',
      '\u0627\u0644\u0645\u0647\u0627\u0645',
      'task',
    ])) {
      return '\u2705';
    }
    if (_containsAny(normalized, const <String>[
      '\u062a\u0642\u0631\u064a\u0631',
      '\u0627\u0644\u062a\u0642\u0627\u0631\u064a\u0631',
      'report',
    ])) {
      return '\u{1F4CA}';
    }
    if (_containsAny(normalized, const <String>[
      '\u0639\u0645\u064a\u0644',
      '\u0627\u0644\u0639\u0645\u0644\u0627\u0621',
      'customer',
    ])) {
      return '\u{1F465}';
    }
    if (_containsAny(normalized, const <String>[
      '\u0645\u0639\u0644\u0648\u0645\u0629',
      '\u0639\u0627\u0645',
      '\u062e\u0627\u0631\u062c\u064a',
      '\u062f\u064a\u0646',
      '\u062a\u0627\u0631\u064a\u062e',
      '\u0644\u063a\u0629',
    ])) {
      return '\u{1F30D}';
    }
    if (_containsAny(normalized, const <String>[
      '\u0647\u0644\u0627',
      '\u0623\u0647\u0644\u0627',
      '\u0645\u0631\u062d\u0628\u0627',
      '\u0643\u064a\u0641 \u062d\u0627\u0644\u0643',
    ])) {
      return '\u{1F44B}';
    }
    return '\u2728';
  }

  String _decorateAssistantReply(String text, {String? userQuestion}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _containsEmoji(trimmed)) {
      return trimmed;
    }

    final emoji = _pickReplyEmoji(
      userQuestion: userQuestion,
      replyText: trimmed,
    );
    final lines = trimmed.split('\n');
    lines[0] = '$emoji ${lines[0]}';
    if (lines.length == 1) {
      return '${lines[0]} \u2728';
    }
    return lines.join('\n');
  }

  String _buildActionSuggestion(String action) {
    final cleaned = action.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return '\u{1F9E9} \u0627\u0634\u0631\u062d \u0644\u064a \u0627\u0644\u062e\u0637\u0648\u0629 \u0627\u0644\u062a\u0627\u0644\u064a\u0629';
    }
    return '\u{1F9E9} \u0627\u0634\u0631\u062d \u0644\u064a \u062e\u0637\u0648\u0629: $cleaned';
  }

  List<String> _dedupeSuggestions(Iterable<String> suggestions) {
    final seen = <String>{};
    final output = <String>[];

    for (final suggestion in suggestions) {
      final normalized = _normalizeForMatching(suggestion);
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      output.add(suggestion.trim());
    }

    return output;
  }

  List<String> _buildGeneralSuggestions(
    String normalizedQuestion,
    String normalizedReply,
  ) {
    final suggestions = <String>[..._generalFollowUpSuggestions];

    if (_containsAny('$normalizedQuestion $normalizedReply', const <String>[
      '\u0625\u0633\u0644\u0627\u0645',
      '\u062f\u064a\u0646',
    ])) {
      suggestions.insert(
        0,
        '\u{1F54C} \u0627\u0634\u0631\u062d\u0647\u0627 \u0644\u064a \u0628\u0644\u063a\u0629 \u0623\u0628\u0633\u0637',
      );
    }
    if (_containsAny('$normalizedQuestion $normalizedReply', const <String>[
      '\u062a\u0627\u0631\u064a\u062e',
      '\u062d\u062f\u062b',
      '\u0632\u0645\u0646',
    ])) {
      suggestions.insert(
        0,
        '\u{1F570}\u{FE0F} \u0627\u0631\u0628\u0637\u0647\u0627 \u0644\u064a \u0628\u0645\u062b\u0627\u0644 \u062a\u0627\u0631\u064a\u062e\u064a',
      );
    }
    if (_containsAny('$normalizedQuestion $normalizedReply', const <String>[
      '\u062a\u0642\u0646\u064a\u0629',
      '\u0630\u0643\u0627\u0621',
      '\u062a\u0637\u0628\u064a\u0642',
    ])) {
      suggestions.insert(
        0,
        '\u{1F4A1} \u0623\u0639\u0637\u0646\u064a \u0641\u0627\u0626\u062f\u0629 \u0639\u0645\u0644\u064a\u0629 \u0645\u0646\u0647\u0627',
      );
    }

    return suggestions;
  }

  List<String> _buildFollowUpSuggestions({
    String? userQuestion,
    required String replyText,
  }) {
    final routeContext = describeMoAssistantRoute(widget.currentRouteName);
    final normalizedQuestion = _normalizeForMatching(userQuestion ?? '');
    final normalizedReply = _normalizeForMatching(replyText);
    final suggestions = <String>[];

    final looksSystemRelated = _containsAny(
      '$normalizedQuestion $normalizedReply ${routeContext?.title ?? ''} ${routeContext?.section ?? ''}',
      const <String>[
        '\u0627\u0644\u0646\u0638\u0627\u0645',
        '\u0627\u0644\u0634\u0627\u0634\u0629',
        '\u0627\u0644\u0635\u0641\u062d\u0629',
        '\u0647\u0646\u0627',
        '\u0637\u0644\u0628\u0627\u062a',
        '\u0645\u062e\u0632\u0648\u0646',
        '\u0635\u064a\u0627\u0646\u0629',
        '\u0645\u0647\u0627\u0645',
        '\u062a\u0642\u0627\u0631\u064a\u0631',
        '\u0639\u0645\u0644\u0627\u0621',
        '\u0645\u0648\u0631\u062f\u064a\u0646',
        '\u0645\u062d\u0637\u0627\u062a',
        'dashboard',
        'order',
      ],
    );

    if (routeContext != null && looksSystemRelated) {
      suggestions.add(
        '\u{1F9ED} \u0645\u0627\u0630\u0627 \u0623\u0641\u0639\u0644 \u0641\u064a ${routeContext.title}\u061f',
      );
      suggestions.addAll(
        routeContext.availableActions.take(2).map(_buildActionSuggestion),
      );
      suggestions.add(
        '\u{1F6E0}\u{FE0F} \u0644\u0648 \u0638\u0647\u0631\u062a \u0645\u0634\u0643\u0644\u0629 \u0647\u0646\u0627 \u0645\u0627\u0630\u0627 \u0623\u0641\u0639\u0644\u061f',
      );
    } else {
      suggestions.addAll(
        _buildGeneralSuggestions(normalizedQuestion, normalizedReply),
      );
    }

    if (_containsAny('$normalizedQuestion $normalizedReply', const <String>[
      '\u0645\u0634\u0643\u0644\u0629',
      '\u062e\u0637\u0623',
      '\u062a\u0639\u0630\u0631',
      '\u0641\u0634\u0644',
    ])) {
      suggestions.insertAll(0, const <String>[
        '\u{1F6E0}\u{FE0F} \u0645\u0627 \u0633\u0628\u0628 \u0627\u0644\u0645\u0634\u0643\u0644\u0629 \u063a\u0627\u0644\u0628\u064b\u0627\u061f',
        '\u{1F501} \u0645\u0627 \u0623\u0648\u0644 \u062e\u0637\u0648\u0629 \u0623\u062c\u0631\u0628\u0647\u0627 \u0627\u0644\u0622\u0646\u061f',
      ]);
    }

    return _dedupeSuggestions(suggestions).take(4).toList(growable: false);
  }

  String _suggestionToPrompt(String suggestion) {
    final parts = suggestion.trim().split(' ');
    if (parts.length > 1 && !_containsLettersOrDigits(parts.first)) {
      return parts.sublist(1).join(' ').trim();
    }
    return suggestion.trim();
  }

  String? _latestAssistantMessageId() {
    for (final message in _messages.reversed) {
      if (message.role == 'assistant') {
        return message.id;
      }
    }
    return null;
  }

  Widget _buildMessageSuggestions(MoAssistantMessage message) {
    if (message.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(
        maxWidth: math.max(220.0, (_panelWidthOverride ?? 300.0) - 64),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '\u0645\u0645\u0643\u0646 \u062a\u0633\u0623\u0644\u0646\u064a \u0623\u064a\u0636\u064b\u0627:',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.suggestions
                .map(
                  (suggestion) => IgnorePointer(
                    ignoring: _isSending,
                    child: ActionChip(
                      backgroundColor: const Color(
                        0xFF0B1E3D,
                      ).withValues(alpha: 0.98),
                      side: BorderSide(
                        color: AppColors.appBarWaterGlow.withValues(
                          alpha: 0.18,
                        ),
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                      onPressed: () {
                        _sendMessage(_suggestionToPrompt(suggestion));
                      },
                      label: Text(suggestion, textDirection: TextDirection.rtl),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required double width,
    required double height,
    required double minWidth,
    required double maxWidth,
    required double minHeight,
    required double maxHeight,
    bool showResizeHandle = true,
  }) {
    return Material(
      key: const ValueKey<String>('mo_assistant_panel'),
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF08172D),
              Color(0xFF0B1F43),
              Color(0xFF122B56),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.appBarWaterBright.withValues(alpha: 0.24),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -70,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        AppColors.appBarWaterGlow.withValues(alpha: 0.24),
                        AppColors.appBarWaterGlow.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              if (showResizeHandle)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildResizeHandle(
                    currentWidth: width,
                    currentHeight: height,
                    minWidth: minWidth,
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                    maxHeight: maxHeight,
                  ),
                ),
              Column(
                children: <Widget>[
                  _buildHeader(),
                  if (_messages.length <= 1) _buildQuickPrompts(),
                  Expanded(child: _buildMessages()),
                  _buildComposer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF67F1C0).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF67F1C0).withValues(alpha: 0.28),
              ),
            ),
            child: const Text(
              'Ollama',
              style: TextStyle(
                color: Color(0xFFBDFCE8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Mo',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'مرشد النظام الذكي',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Color(0xFFD4E4FF), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: <Color>[
                  AppColors.appBarWaterBright,
                  AppColors.secondaryTeal,
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: _quickPrompts
            .map(
              (prompt) => ActionChip(
                backgroundColor: const Color(
                  0xFF13315F,
                ).withValues(alpha: 0.92),
                side: BorderSide(
                  color: AppColors.appBarWaterGlow.withValues(alpha: 0.22),
                ),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () {
                  _sendMessage(prompt);
                },
                label: Text(prompt),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildMessages() {
    final latestAssistantId = _latestAssistantMessageId();

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: _messages.length + (_isSending ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isSending && index == _messages.length) {
            return const _MoTypingBubble();
          }

          final item = _messages[index];
          final isUser = item.role == 'user';
          final showSuggestions =
              !isUser &&
              item.id == latestAssistantId &&
              item.suggestions.isNotEmpty;

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: math.max(
                        220.0,
                        (_panelWidthOverride ?? 300.0) - 64,
                      ),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: isUser
                          ? const LinearGradient(
                              colors: <Color>[
                                AppColors.appBarWaterMid,
                                AppColors.appBarWaterBright,
                              ],
                            )
                          : null,
                      color: isUser
                          ? null
                          : const Color(0xFF17335E).withValues(alpha: 0.96),
                      border: Border.all(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.appBarWaterGlow.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      item.text,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (showSuggestions) _buildMessageSuggestions(item),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اسأل Mo عن النظام أو أي معلومة عامة...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.appBarWaterGlow,
                  ),
                ),
              ),
              onSubmitted: (_) {
                _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: _isSending
                      ? const <Color>[Color(0xFF0A274B), Color(0xFF1B5EA9)]
                      : const <Color>[
                          AppColors.secondaryTeal,
                          AppColors.appBarWaterBright,
                        ],
                ),
              ),
              child: IconButton(
                onPressed: _isSending
                    ? _cancelSending
                    : () {
                        _sendMessage();
                      },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: _isSending
                      ? const Icon(
                          Icons.stop_rounded,
                          key: ValueKey<String>('mo_stop'),
                          color: Colors.white,
                          size: 24,
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          key: ValueKey<String>('mo_send'),
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      final media = MediaQuery.of(context);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : media.size.width)
                  .toDouble();
          final height =
              (constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : media.size.height)
                  .toDouble();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: _buildPanel(
              context,
              width: width,
              height: height,
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height,
              showResizeHandle: false,
            ),
          );
        },
      );
    }

    final media = MediaQuery.of(context);
    final size = media.size;
    final bottomInset = media.padding.bottom + media.viewInsets.bottom + 22;
    final launcherLeft = _clampLauncherLeft(
      _launcherLeft ?? (size.width - _launcherSize - _launcherMargin),
      size,
    );
    final launcherTop = _clampLauncherTop(
      _launcherTop ?? (size.height - _launcherSize - bottomInset),
      size,
      media.padding,
      bottomInset,
    );
    final panelMinWidth = _panelMinWidth(media);
    final panelMaxWidth = _panelMaxWidth(media);
    final panelMinHeight = _panelMinHeight(media);
    final panelMaxHeight = _panelMaxHeight(media);
    final panelWidth = (_panelWidthOverride ?? _defaultPanelWidth(media))
        .clamp(panelMinWidth, panelMaxWidth)
        .toDouble();
    final panelHeight = (_panelHeightOverride ?? _defaultPanelHeight(media))
        .clamp(panelMinHeight, panelMaxHeight)
        .toDouble();
    final minPanelTop = media.padding.top + 8;
    final maxPanelTop = math.max(
      minPanelTop,
      size.height - panelHeight - bottomInset,
    );
    final panelLeft = (launcherLeft + _launcherSize - panelWidth)
        .clamp(
          _launcherMargin,
          math.max(_launcherMargin, size.width - panelWidth - _launcherMargin),
        )
        .toDouble();
    final preferPanelAbove =
        launcherTop >= panelHeight + _panelGap + minPanelTop;
    final panelTop =
        (preferPanelAbove
                ? launcherTop - panelHeight - _panelGap
                : launcherTop + _launcherSize + _panelGap)
            .clamp(minPanelTop, maxPanelTop)
            .toDouble();

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: AnimatedOpacity(
              opacity: _isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: _closePanel,
                child: Container(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ),
        if (_isOpen)
          Positioned(
            left: panelLeft,
            top: panelTop,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeInCubic,
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.90, end: 1).animate(curved),
                      alignment: Alignment.bottomRight,
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildPanel(
                context,
                width: panelWidth,
                height: panelHeight,
                minWidth: panelMinWidth,
                maxWidth: panelMaxWidth,
                minHeight: panelMinHeight,
                maxHeight: panelMaxHeight,
              ),
            ),
          ),
        Positioned(
          left: launcherLeft,
          top: launcherTop,
          child: GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onTap: _togglePanel,
            onPanStart: (details) {
              _dragTouchOffset = details.localPosition;
              setState(() {
                _updateLauncherFromGlobal(
                  globalPosition: details.globalPosition,
                  size: size,
                  padding: media.padding,
                  bottomInset: bottomInset,
                );
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _updateLauncherFromGlobal(
                  globalPosition: details.globalPosition,
                  size: size,
                  padding: media.padding,
                  bottomInset: bottomInset,
                );
              });
            },
            onPanEnd: (_) {
              _dragTouchOffset = null;
            },
            onPanCancel: () {
              _dragTouchOffset = null;
            },
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildLauncherButton(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoTypingBubble extends StatefulWidget {
  const _MoTypingBubble();

  @override
  State<_MoTypingBubble> createState() => _MoTypingBubbleState();
}

class _MoTypingBubbleState extends State<_MoTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF17335E).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.appBarWaterGlow.withValues(alpha: 0.16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (index) {
                final shifted = (_controller.value + (index * 0.18)) % 1;
                final glow = (math.sin(shifted * math.pi * 2) + 1) / 2;
                return Container(
                  width: 7,
                  height: 7 + (glow * 3),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.34 + (glow * 0.48)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
