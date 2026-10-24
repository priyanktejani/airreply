import 'dart:async';

import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/notifications/domain/send_reply.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reply bar at the bottom of a notification. With a hardware keyboard (desktop, web), Enter sends and
/// Shift+Enter starts a new line.
///
/// The field clears as soon as the reply is queued: the reply shows in the thread at once ("Sending") and its status
/// follows the phone's report, so there is nothing to wait for here. On failure the words come back.
class ReplyComposer extends ConsumerStatefulWidget {
  const ReplyComposer({required this.pairId, required this.notification, this.autofocus = false, super.key});

  final String pairId;
  final MirroredNotification notification;
  final bool autofocus;

  @override
  ConsumerState<ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends ConsumerState<ReplyComposer> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !AppPlatform.prefersKeyboardShortcuts) return KeyEventResult.ignored;
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored; // Shift+Enter: new line
    _send();
    return KeyEventResult.handled;
  }

  void _send() {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    final sending = ref.read(sendReplyProvider(widget.pairId)).call(widget.notification, text);
    unawaited(
      sending.then(
        (_) => ref.success(),
        onError: (Object e) {
          ref.failure();
          if (!mounted) return;
          if (_text.text.isEmpty) _text.text = text; // give the words back so nothing is lost
          context.showError(e);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canSend = _text.text.trim().isNotEmpty;
    final content = widget.notification.content;
    final to = content.conversationTitle ?? content.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x3, Space.x3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: SendReply.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: AppPlatform.prefersKeyboardShortcuts
                      ? TextInputAction.newline
                      : TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: to.isEmpty ? 'Reply' : 'Reply to $to',
                  ),
                ),
              ),
              const SizedBox(width: Space.x2),
              AnimatedOpacity(
                duration: Motion.fast,
                opacity: canSend ? 1 : 0.4,
                child: IconButton.filled(
                  tooltip: AppPlatform.prefersKeyboardShortcuts ? 'Send (Enter)' : 'Send',
                  onPressed: canSend ? _send : null,
                  style: IconButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.paper,
                    disabledBackgroundColor: c.ink,
                    disabledForegroundColor: c.paper,
                    minimumSize: const Size(48, 48),
                    shape: const RoundedRectangleBorder(borderRadius: Radii.controlBorder),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
