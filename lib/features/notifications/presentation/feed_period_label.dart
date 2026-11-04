import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/l10n/app_localizations.dart';

/// A [FeedPeriod] as the filters name it.
extension FeedPeriodLabel on FeedPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    FeedPeriod.all => l10n.periodAnyTime,
    FeedPeriod.today => l10n.periodToday,
    FeedPeriod.week => l10n.periodWeek,
  };
}
