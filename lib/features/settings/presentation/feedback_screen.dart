import 'package:air_reply/core/config/support.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/domain/feedback.dart';
import 'package:air_reply/features/settings/feedback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Report a problem or suggest a feature: what kind, which part of the app, and the person's own words. Sending
/// hands it, written out, to the email app.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({this.kind = FeedbackKind.problem, super.key});

  final FeedbackKind kind;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  late FeedbackKind _kind = widget.kind;
  FeedbackArea? _area;
  var _includeDetails = true;
  var _checked = false;
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _longEnough => _message.text.trim().length >= FeedbackMessage.minLength;

  Future<void> _send() async {
    setState(() => _checked = true);
    if (!_longEnough) return;
    final l10n = context.l10n;
    final session = ref.read(deviceSessionProvider).value;
    final details = _includeDetails
        ? {
            ...await ref.read(deviceDetailsProvider)(),
            'App language': l10n.localeName,
            'Role': switch (session?.role) {
              DeviceRole.sender => 'shares notifications',
              DeviceRole.receiver => 'views and replies',
              null => 'not chosen',
            },
            'Paired devices': '${session?.pairs.length ?? 0}',
          }
        : null;
    final message = FeedbackMessage(
      kind: _kind,
      area: _area ?? FeedbackArea.other,
      message: _message.text,
      details: details,
    );
    final opened = await ref.read(openEmailProvider)(message.mailto(supportEmail));
    if (!mounted) return;
    if (opened) {
      context
        ..showMessage(l10n.feedbackSent, icon: AppIcons.check)
        ..pop();
    } else {
      context.showMessage(l10n.feedbackNoEmailApp, icon: AppIcons.errorOutline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = _kind == FeedbackKind.problem;
    return Scaffold(
      body: GlassScrollPage(
        title: Text(problem ? l10n.feedbackReportTitle : l10n.feedbackIdeaTitle),
        slivers: [
          SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.base),
              _Label(l10n.feedbackKindLabel),
              SegmentedButton<FeedbackKind>(
                segments: [
                  ButtonSegment(
                    value: FeedbackKind.problem,
                    icon: const Icon(AppIcons.bug),
                    label: Text(l10n.feedbackKindProblem),
                  ),
                  ButtonSegment(
                    value: FeedbackKind.idea,
                    icon: const Icon(AppIcons.lightbulb),
                    label: Text(l10n.feedbackKindIdea),
                  ),
                ],
                selected: {_kind},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              _Label(l10n.feedbackAreaLabel),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final area in FeedbackArea.values)
                    ChoiceChip(
                      label: Text(_areaName(l10n, area)),
                      selected: _area == area,
                      onSelected: (on) => setState(() => _area = on ? area : null),
                    ),
                ],
              ),
              _Label(l10n.feedbackMessageLabel),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 12,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_checked) setState(() {});
                },
                decoration: InputDecoration(
                  hintText: problem ? l10n.feedbackProblemHint : l10n.feedbackIdeaHint,
                  hintMaxLines: 3,
                  errorText: _checked && !_longEnough ? l10n.feedbackTooShort : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CardGroup(
                children: [
                  SwitchRow(
                    icon: AppIcons.smartphone,
                    title: l10n.feedbackIncludeDetails,
                    subtitle: l10n.feedbackDetailsSubtitle,
                    value: _includeDetails,
                    onChanged: (on) => setState(() => _includeDetails = on),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AsyncButton(label: l10n.actionSend, icon: AppIcons.send, expand: true, onPressed: _send),
              SizedBox(height: AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ],
      ),
    );
  }

  static String _areaName(AppLocalizations l10n, FeedbackArea area) => switch (area) {
    FeedbackArea.notifications => l10n.feedbackAreaNotifications,
    FeedbackArea.replies => l10n.feedbackAreaReplies,
    FeedbackArea.pairing => l10n.feedbackAreaPairing,
    FeedbackArea.alerts => l10n.feedbackAreaAlerts,
    FeedbackArea.sync => l10n.feedbackAreaSync,
    FeedbackArea.design => l10n.feedbackAreaDesign,
    FeedbackArea.other => l10n.feedbackAreaOther,
  };
}

/// A field's name above it.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(text, style: AppType.label.copyWith(color: context.palette.muted)),
  );
}
