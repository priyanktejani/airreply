/// How current a pair's data is on this device, as the backend connection reports it.
enum SyncHealth {
  /// No answer from the server yet.
  connecting,

  /// The latest data came from the server.
  live,

  /// The server cannot be reached; what is shown comes from the local cache.
  offline,
}

final class SyncState {
  const SyncState(this.health, {this.lastSyncedAt});

  static const connecting = SyncState(SyncHealth.connecting);

  final SyncHealth health;

  /// When this device was last in sync with the server, if ever in this session: the latest server answer while
  /// live, the moment the connection dropped once offline.
  final DateTime? lastSyncedAt;

  /// Next state given whether this update came from the server. A cache-only update before the first server answer
  /// means we are still connecting; after it, that we went offline (and were in sync until [now]).
  SyncState next({required bool fromServer, required DateTime now}) {
    if (fromServer) return SyncState(SyncHealth.live, lastSyncedAt: now);
    return switch (health) {
      SyncHealth.live => SyncState(SyncHealth.offline, lastSyncedAt: now),
      _ => SyncState(lastSyncedAt == null ? SyncHealth.connecting : SyncHealth.offline, lastSyncedAt: lastSyncedAt),
    };
  }
}
