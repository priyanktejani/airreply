import 'dart:async';

import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/bottom_fade.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
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
  const ReplyComposer({
    required this.pairId,
    required this.notification,
    this.recipient,
    this.autofocus = false,
    super.key,
  });

  final String pairId;

  /// Who the reply goes to, for the hint ("Reply to Alex"); the notification's own names by default.
  final String? recipient;
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
    final c = context.palette;
    final canSend = _text.text.trim().isNotEmpty;
    final content = widget.notification.content;
    // never "Reply to You": your own message is titled after you, not the person you are talking to
    final named = content.conversationTitle ?? (isTitledAsUser(content) ? '' : content.title);
    final to = widget.recipient ?? named;

    final quick = context.motion(AppMotion.medium);
    final field = OutlineInputBorder(
      borderRadius: AppRadius.xlBorder,
      borderSide: BorderSide(color: c.line),
    );
    // the message box floats as a glass panel over the conversation, clear of the home indicator and the keyboard
    return BottomFade(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: ResponsiveCenter(
          child: GlassContainer(
            strong: true,
            floating: true,
            borderRadius: AppRadius.xxlBorder,
            padding: const EdgeInsets.all(AppSpacing.sm),
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
                      filled: true,
                      fillColor: c.soft,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                      border: field,
                      enabledBorder: field,
                      focusedBorder: field.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
                      hintText: to.isEmpty ? context.l10n.replyHint : context.l10n.replyToHint(to),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedScale(
                  scale: canSend ? 1 : .88,
                  duration: quick,
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: canSend ? 1 : .6,
                    duration: quick,
                    child: IconButton.filled(
                      tooltip: AppPlatform.prefersKeyboardShortcuts
                          ? context.l10n.sendWithEnter
                          : context.l10n.actionSend,
                      onPressed: canSend ? _send : null,
                      style: IconButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.accentInk,
                        disabledBackgroundColor: c.accent,
                        disabledForegroundColor: c.accentInk,
                        minimumSize: const Size(AppDimensions.touchTarget, AppDimensions.touchTarget),
                      ),
                      icon: const Icon(AppIcons.send, size: AppDimensions.iconMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
