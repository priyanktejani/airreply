import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';

/// Local, secure persistence of removed devices whose history is kept (see [ArchivedPair]).
abstract interface class ArchivedPairsStore {
  Future<List<ArchivedPair>> readAll();

  /// Adds the pair, or replaces the one with the same pair id.
  Future<void> save(ArchivedPair pair);

  Future<void> remove(String pairId);
}
