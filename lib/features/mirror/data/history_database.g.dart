// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_database.dart';

// ignore_for_file: type=lint
class $HistoryNotificationsTable extends HistoryNotifications
    with TableInfo<$HistoryNotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta('postedAt');
  @override
  late final GeneratedColumn<int> postedAt = GeneratedColumn<int>(
    'posted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyHashMeta = const VerificationMeta('keyHash');
  @override
  late final GeneratedColumn<String> keyHash = GeneratedColumn<String>(
    'key_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canReplyMeta = const VerificationMeta('canReply');
  @override
  late final GeneratedColumn<bool> canReply = GeneratedColumn<bool>(
    'can_reply',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("can_reply" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta('dismissed');
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("dismissed" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [pairId, id, payload, postedAt, keyHash, canReply, dismissed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<NotificationRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta, pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('posted_at')) {
      context.handle(_postedAtMeta, postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta));
    } else if (isInserting) {
      context.missing(_postedAtMeta);
    }
    if (data.containsKey('key_hash')) {
      context.handle(_keyHashMeta, keyHash.isAcceptableOrUnknown(data['key_hash']!, _keyHashMeta));
    }
    if (data.containsKey('can_reply')) {
      context.handle(_canReplyMeta, canReply.isAcceptableOrUnknown(data['can_reply']!, _canReplyMeta));
    }
    if (data.containsKey('dismissed')) {
      context.handle(_dismissedMeta, dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, id};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      pairId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair_id'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payload: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      postedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}posted_at'])!,
      keyHash: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key_hash']),
      canReply: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}can_reply'])!,
      dismissed: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}dismissed'])!,
    );
  }

  @override
  $HistoryNotificationsTable createAlias(String alias) {
    return $HistoryNotificationsTable(attachedDatabase, alias);
  }
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String pairId;
  final String id;
  final String payload;
  final int postedAt;

  /// The blind index of the source notification's key: how a later dismissal finds it.
  final String? keyHash;
  final bool canReply;

  /// Flagged dismissed in the document itself (senders before dismissals had their own documents).
  final bool dismissed;
  const NotificationRow({
    required this.pairId,
    required this.id,
    required this.payload,
    required this.postedAt,
    this.keyHash,
    required this.canReply,
    required this.dismissed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['posted_at'] = Variable<int>(postedAt);
    if (!nullToAbsent || keyHash != null) {
      map['key_hash'] = Variable<String>(keyHash);
    }
    map['can_reply'] = Variable<bool>(canReply);
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  HistoryNotificationsCompanion toCompanion(bool nullToAbsent) {
    return HistoryNotificationsCompanion(
      pairId: Value(pairId),
      id: Value(id),
      payload: Value(payload),
      postedAt: Value(postedAt),
      keyHash: keyHash == null && nullToAbsent ? const Value.absent() : Value(keyHash),
      canReply: Value(canReply),
      dismissed: Value(dismissed),
    );
  }

  factory NotificationRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      postedAt: serializer.fromJson<int>(json['postedAt']),
      keyHash: serializer.fromJson<String?>(json['keyHash']),
      canReply: serializer.fromJson<bool>(json['canReply']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'postedAt': serializer.toJson<int>(postedAt),
      'keyHash': serializer.toJson<String?>(keyHash),
      'canReply': serializer.toJson<bool>(canReply),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  NotificationRow copyWith({
    String? pairId,
    String? id,
    String? payload,
    int? postedAt,
    Value<String?> keyHash = const Value.absent(),
    bool? canReply,
    bool? dismissed,
  }) => NotificationRow(
    pairId: pairId ?? this.pairId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    postedAt: postedAt ?? this.postedAt,
    keyHash: keyHash.present ? keyHash.value : this.keyHash,
    canReply: canReply ?? this.canReply,
    dismissed: dismissed ?? this.dismissed,
  );
  NotificationRow copyWithCompanion(HistoryNotificationsCompanion data) {
    return NotificationRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      keyHash: data.keyHash.present ? data.keyHash.value : this.keyHash,
      canReply: data.canReply.present ? data.canReply.value : this.canReply,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('postedAt: $postedAt, ')
          ..write('keyHash: $keyHash, ')
          ..write('canReply: $canReply, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pairId, id, payload, postedAt, keyHash, canReply, dismissed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.pairId == this.pairId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.postedAt == this.postedAt &&
          other.keyHash == this.keyHash &&
          other.canReply == this.canReply &&
          other.dismissed == this.dismissed);
}

class HistoryNotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> pairId;
  final Value<String> id;
  final Value<String> payload;
  final Value<int> postedAt;
  final Value<String?> keyHash;
  final Value<bool> canReply;
  final Value<bool> dismissed;
  final Value<int> rowid;
  const HistoryNotificationsCompanion({
    this.pairId = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.keyHash = const Value.absent(),
    this.canReply = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryNotificationsCompanion.insert({
    required String pairId,
    required String id,
    required String payload,
    required int postedAt,
    this.keyHash = const Value.absent(),
    this.canReply = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       id = Value(id),
       payload = Value(payload),
       postedAt = Value(postedAt);
  static Insertable<NotificationRow> custom({
    Expression<String>? pairId,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? postedAt,
    Expression<String>? keyHash,
    Expression<bool>? canReply,
    Expression<bool>? dismissed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (postedAt != null) 'posted_at': postedAt,
      if (keyHash != null) 'key_hash': keyHash,
      if (canReply != null) 'can_reply': canReply,
      if (dismissed != null) 'dismissed': dismissed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryNotificationsCompanion copyWith({
    Value<String>? pairId,
    Value<String>? id,
    Value<String>? payload,
    Value<int>? postedAt,
    Value<String?>? keyHash,
    Value<bool>? canReply,
    Value<bool>? dismissed,
    Value<int>? rowid,
  }) {
    return HistoryNotificationsCompanion(
      pairId: pairId ?? this.pairId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      postedAt: postedAt ?? this.postedAt,
      keyHash: keyHash ?? this.keyHash,
      canReply: canReply ?? this.canReply,
      dismissed: dismissed ?? this.dismissed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<int>(postedAt.value);
    }
    if (keyHash.present) {
      map['key_hash'] = Variable<String>(keyHash.value);
    }
    if (canReply.present) {
      map['can_reply'] = Variable<bool>(canReply.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryNotificationsCompanion(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('postedAt: $postedAt, ')
          ..write('keyHash: $keyHash, ')
          ..write('canReply: $canReply, ')
          ..write('dismissed: $dismissed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryRepliesTable extends HistoryReplies with TableInfo<$HistoryRepliesTable, ReplyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryRepliesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<String> notificationId = GeneratedColumn<String>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pairId, id, notificationId, payload, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_replies';
  @override
  VerificationContext validateIntegrity(Insertable<ReplyRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta, pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(data['notification_id']!, _notificationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, id};
  @override
  ReplyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplyRow(
      pairId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair_id'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HistoryRepliesTable createAlias(String alias) {
    return $HistoryRepliesTable(attachedDatabase, alias);
  }
}

class ReplyRow extends DataClass implements Insertable<ReplyRow> {
  final String pairId;
  final String id;
  final String notificationId;
  final String payload;

  /// `ReplyStatus.wire`.
  final String status;
  final int createdAt;
  const ReplyRow({
    required this.pairId,
    required this.id,
    required this.notificationId,
    required this.payload,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['id'] = Variable<String>(id);
    map['notification_id'] = Variable<String>(notificationId);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  HistoryRepliesCompanion toCompanion(bool nullToAbsent) {
    return HistoryRepliesCompanion(
      pairId: Value(pairId),
      id: Value(id),
      notificationId: Value(notificationId),
      payload: Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ReplyRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplyRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      id: serializer.fromJson<String>(json['id']),
      notificationId: serializer.fromJson<String>(json['notificationId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'id': serializer.toJson<String>(id),
      'notificationId': serializer.toJson<String>(notificationId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReplyRow copyWith({
    String? pairId,
    String? id,
    String? notificationId,
    String? payload,
    String? status,
    int? createdAt,
  }) => ReplyRow(
    pairId: pairId ?? this.pairId,
    id: id ?? this.id,
    notificationId: notificationId ?? this.notificationId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  ReplyRow copyWithCompanion(HistoryRepliesCompanion data) {
    return ReplyRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      id: data.id.present ? data.id.value : this.id,
      notificationId: data.notificationId.present ? data.notificationId.value : this.notificationId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplyRow(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pairId, id, notificationId, payload, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplyRow &&
          other.pairId == this.pairId &&
          other.id == this.id &&
          other.notificationId == this.notificationId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class HistoryRepliesCompanion extends UpdateCompanion<ReplyRow> {
  final Value<String> pairId;
  final Value<String> id;
  final Value<String> notificationId;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const HistoryRepliesCompanion({
    this.pairId = const Value.absent(),
    this.id = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryRepliesCompanion.insert({
    required String pairId,
    required String id,
    required String notificationId,
    required String payload,
    required String status,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       id = Value(id),
       notificationId = Value(notificationId),
       payload = Value(payload),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<ReplyRow> custom({
    Expression<String>? pairId,
    Expression<String>? id,
    Expression<String>? notificationId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (id != null) 'id': id,
      if (notificationId != null) 'notification_id': notificationId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryRepliesCompanion copyWith({
    Value<String>? pairId,
    Value<String>? id,
    Value<String>? notificationId,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return HistoryRepliesCompanion(
      pairId: pairId ?? this.pairId,
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<String>(notificationId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRepliesCompanion(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('notificationId: $notificationId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryDismissalsTable extends HistoryDismissals with TableInfo<$HistoryDismissalsTable, DismissalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryDismissalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyHashMeta = const VerificationMeta('keyHash');
  @override
  late final GeneratedColumn<String> keyHash = GeneratedColumn<String>(
    'key_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pairId, keyHash, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_dismissals';
  @override
  VerificationContext validateIntegrity(Insertable<DismissalRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta, pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('key_hash')) {
      context.handle(_keyHashMeta, keyHash.isAcceptableOrUnknown(data['key_hash']!, _keyHashMeta));
    } else if (isInserting) {
      context.missing(_keyHashMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, keyHash};
  @override
  DismissalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DismissalRow(
      pairId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair_id'])!,
      keyHash: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key_hash'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at'])!,
    );
  }

  @override
  $HistoryDismissalsTable createAlias(String alias) {
    return $HistoryDismissalsTable(attachedDatabase, alias);
  }
}

class DismissalRow extends DataClass implements Insertable<DismissalRow> {
  final String pairId;
  final String keyHash;
  final int at;
  const DismissalRow({required this.pairId, required this.keyHash, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['key_hash'] = Variable<String>(keyHash);
    map['at'] = Variable<int>(at);
    return map;
  }

  HistoryDismissalsCompanion toCompanion(bool nullToAbsent) {
    return HistoryDismissalsCompanion(pairId: Value(pairId), keyHash: Value(keyHash), at: Value(at));
  }

  factory DismissalRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DismissalRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      keyHash: serializer.fromJson<String>(json['keyHash']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'keyHash': serializer.toJson<String>(keyHash),
      'at': serializer.toJson<int>(at),
    };
  }

  DismissalRow copyWith({String? pairId, String? keyHash, int? at}) =>
      DismissalRow(pairId: pairId ?? this.pairId, keyHash: keyHash ?? this.keyHash, at: at ?? this.at);
  DismissalRow copyWithCompanion(HistoryDismissalsCompanion data) {
    return DismissalRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      keyHash: data.keyHash.present ? data.keyHash.value : this.keyHash,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DismissalRow(')
          ..write('pairId: $pairId, ')
          ..write('keyHash: $keyHash, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pairId, keyHash, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DismissalRow && other.pairId == this.pairId && other.keyHash == this.keyHash && other.at == this.at);
}

class HistoryDismissalsCompanion extends UpdateCompanion<DismissalRow> {
  final Value<String> pairId;
  final Value<String> keyHash;
  final Value<int> at;
  final Value<int> rowid;
  const HistoryDismissalsCompanion({
    this.pairId = const Value.absent(),
    this.keyHash = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryDismissalsCompanion.insert({
    required String pairId,
    required String keyHash,
    required int at,
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       keyHash = Value(keyHash),
       at = Value(at);
  static Insertable<DismissalRow> custom({
    Expression<String>? pairId,
    Expression<String>? keyHash,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (keyHash != null) 'key_hash': keyHash,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryDismissalsCompanion copyWith({
    Value<String>? pairId,
    Value<String>? keyHash,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return HistoryDismissalsCompanion(
      pairId: pairId ?? this.pairId,
      keyHash: keyHash ?? this.keyHash,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (keyHash.present) {
      map['key_hash'] = Variable<String>(keyHash.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryDismissalsCompanion(')
          ..write('pairId: $pairId, ')
          ..write('keyHash: $keyHash, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryPublishedTable extends HistoryPublished with TableInfo<$HistoryPublishedTable, PublishedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryPublishedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyHashMeta = const VerificationMeta('keyHash');
  @override
  late final GeneratedColumn<String> keyHash = GeneratedColumn<String>(
    'key_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pairId, keyHash, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_published';
  @override
  VerificationContext validateIntegrity(Insertable<PublishedRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta, pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('key_hash')) {
      context.handle(_keyHashMeta, keyHash.isAcceptableOrUnknown(data['key_hash']!, _keyHashMeta));
    } else if (isInserting) {
      context.missing(_keyHashMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, keyHash};
  @override
  PublishedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PublishedRow(
      pairId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair_id'])!,
      keyHash: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key_hash'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at'])!,
    );
  }

  @override
  $HistoryPublishedTable createAlias(String alias) {
    return $HistoryPublishedTable(attachedDatabase, alias);
  }
}

class PublishedRow extends DataClass implements Insertable<PublishedRow> {
  final String pairId;
  final String keyHash;
  final int at;
  const PublishedRow({required this.pairId, required this.keyHash, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['key_hash'] = Variable<String>(keyHash);
    map['at'] = Variable<int>(at);
    return map;
  }

  HistoryPublishedCompanion toCompanion(bool nullToAbsent) {
    return HistoryPublishedCompanion(pairId: Value(pairId), keyHash: Value(keyHash), at: Value(at));
  }

  factory PublishedRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PublishedRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      keyHash: serializer.fromJson<String>(json['keyHash']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'keyHash': serializer.toJson<String>(keyHash),
      'at': serializer.toJson<int>(at),
    };
  }

  PublishedRow copyWith({String? pairId, String? keyHash, int? at}) =>
      PublishedRow(pairId: pairId ?? this.pairId, keyHash: keyHash ?? this.keyHash, at: at ?? this.at);
  PublishedRow copyWithCompanion(HistoryPublishedCompanion data) {
    return PublishedRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      keyHash: data.keyHash.present ? data.keyHash.value : this.keyHash,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PublishedRow(')
          ..write('pairId: $pairId, ')
          ..write('keyHash: $keyHash, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pairId, keyHash, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublishedRow && other.pairId == this.pairId && other.keyHash == this.keyHash && other.at == this.at);
}

class HistoryPublishedCompanion extends UpdateCompanion<PublishedRow> {
  final Value<String> pairId;
  final Value<String> keyHash;
  final Value<int> at;
  final Value<int> rowid;
  const HistoryPublishedCompanion({
    this.pairId = const Value.absent(),
    this.keyHash = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryPublishedCompanion.insert({
    required String pairId,
    required String keyHash,
    required int at,
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       keyHash = Value(keyHash),
       at = Value(at);
  static Insertable<PublishedRow> custom({
    Expression<String>? pairId,
    Expression<String>? keyHash,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (keyHash != null) 'key_hash': keyHash,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryPublishedCompanion copyWith({
    Value<String>? pairId,
    Value<String>? keyHash,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return HistoryPublishedCompanion(
      pairId: pairId ?? this.pairId,
      keyHash: keyHash ?? this.keyHash,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (keyHash.present) {
      map['key_hash'] = Variable<String>(keyHash.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryPublishedCompanion(')
          ..write('pairId: $pairId, ')
          ..write('keyHash: $keyHash, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistorySearchTable extends HistorySearch with TableInfo<$HistorySearchTable, SearchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistorySearchTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pairId, id, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_search';
  @override
  VerificationContext validateIntegrity(Insertable<SearchRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_id')) {
      context.handle(_pairIdMeta, pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta));
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairId, id};
  @override
  SearchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchRow(
      pairId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair_id'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $HistorySearchTable createAlias(String alias) {
    return $HistorySearchTable(attachedDatabase, alias);
  }
}

class SearchRow extends DataClass implements Insertable<SearchRow> {
  final String pairId;
  final String id;
  final String content;
  const SearchRow({required this.pairId, required this.id, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_id'] = Variable<String>(pairId);
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    return map;
  }

  HistorySearchCompanion toCompanion(bool nullToAbsent) {
    return HistorySearchCompanion(pairId: Value(pairId), id: Value(id), content: Value(content));
  }

  factory SearchRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchRow(
      pairId: serializer.fromJson<String>(json['pairId']),
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairId': serializer.toJson<String>(pairId),
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
    };
  }

  SearchRow copyWith({String? pairId, String? id, String? content}) =>
      SearchRow(pairId: pairId ?? this.pairId, id: id ?? this.id, content: content ?? this.content);
  SearchRow copyWithCompanion(HistorySearchCompanion data) {
    return SearchRow(
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchRow(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pairId, id, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchRow && other.pairId == this.pairId && other.id == this.id && other.content == this.content);
}

class HistorySearchCompanion extends UpdateCompanion<SearchRow> {
  final Value<String> pairId;
  final Value<String> id;
  final Value<String> content;
  final Value<int> rowid;
  const HistorySearchCompanion({
    this.pairId = const Value.absent(),
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistorySearchCompanion.insert({
    required String pairId,
    required String id,
    required String content,
    this.rowid = const Value.absent(),
  }) : pairId = Value(pairId),
       id = Value(id),
       content = Value(content);
  static Insertable<SearchRow> custom({
    Expression<String>? pairId,
    Expression<String>? id,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairId != null) 'pair_id': pairId,
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistorySearchCompanion copyWith({
    Value<String>? pairId,
    Value<String>? id,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return HistorySearchCompanion(
      pairId: pairId ?? this.pairId,
      id: id ?? this.id,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistorySearchCompanion(')
          ..write('pairId: $pairId, ')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HistoryDatabase extends GeneratedDatabase {
  _$HistoryDatabase(QueryExecutor e) : super(e);
  $HistoryDatabaseManager get managers => $HistoryDatabaseManager(this);
  late final $HistoryNotificationsTable historyNotifications = $HistoryNotificationsTable(this);
  late final $HistoryRepliesTable historyReplies = $HistoryRepliesTable(this);
  late final $HistoryDismissalsTable historyDismissals = $HistoryDismissalsTable(this);
  late final $HistoryPublishedTable historyPublished = $HistoryPublishedTable(this);
  late final $HistorySearchTable historySearch = $HistorySearchTable(this);
  late final Index notificationsByTime = Index(
    'notifications_by_time',
    'CREATE INDEX notifications_by_time ON history_notifications (pair_id, posted_at)',
  );
  late final Index repliesByTime = Index(
    'replies_by_time',
    'CREATE INDEX replies_by_time ON history_replies (pair_id, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    historyNotifications,
    historyReplies,
    historyDismissals,
    historyPublished,
    historySearch,
    notificationsByTime,
    repliesByTime,
  ];
}

typedef $$HistoryNotificationsTableCreateCompanionBuilder =
    HistoryNotificationsCompanion Function({
      required String pairId,
      required String id,
      required String payload,
      required int postedAt,
      Value<String?> keyHash,
      Value<bool> canReply,
      Value<bool> dismissed,
      Value<int> rowid,
    });
typedef $$HistoryNotificationsTableUpdateCompanionBuilder =
    HistoryNotificationsCompanion Function({
      Value<String> pairId,
      Value<String> id,
      Value<String> payload,
      Value<int> postedAt,
      Value<String?> keyHash,
      Value<bool> canReply,
      Value<bool> dismissed,
      Value<int> rowid,
    });

class $$HistoryNotificationsTableFilterComposer extends Composer<_$HistoryDatabase, $HistoryNotificationsTable> {
  $$HistoryNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get canReply =>
      $composableBuilder(column: $table.canReply, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => ColumnFilters(column));
}

class $$HistoryNotificationsTableOrderingComposer extends Composer<_$HistoryDatabase, $HistoryNotificationsTable> {
  $$HistoryNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get canReply =>
      $composableBuilder(column: $table.canReply, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => ColumnOrderings(column));
}

class $$HistoryNotificationsTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistoryNotificationsTable> {
  $$HistoryNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId => $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload => $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get postedAt => $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<String> get keyHash => $composableBuilder(column: $table.keyHash, builder: (column) => column);

  GeneratedColumn<bool> get canReply => $composableBuilder(column: $table.canReply, builder: (column) => column);

  GeneratedColumn<bool> get dismissed => $composableBuilder(column: $table.dismissed, builder: (column) => column);
}

class $$HistoryNotificationsTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistoryNotificationsTable,
          NotificationRow,
          $$HistoryNotificationsTableFilterComposer,
          $$HistoryNotificationsTableOrderingComposer,
          $$HistoryNotificationsTableAnnotationComposer,
          $$HistoryNotificationsTableCreateCompanionBuilder,
          $$HistoryNotificationsTableUpdateCompanionBuilder,
          (NotificationRow, BaseReferences<_$HistoryDatabase, $HistoryNotificationsTable, NotificationRow>),
          NotificationRow,
          PrefetchHooks Function()
        > {
  $$HistoryNotificationsTableTableManager(_$HistoryDatabase db, $HistoryNotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> postedAt = const Value.absent(),
                Value<String?> keyHash = const Value.absent(),
                Value<bool> canReply = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryNotificationsCompanion(
                pairId: pairId,
                id: id,
                payload: payload,
                postedAt: postedAt,
                keyHash: keyHash,
                canReply: canReply,
                dismissed: dismissed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pairId,
                required String id,
                required String payload,
                required int postedAt,
                Value<String?> keyHash = const Value.absent(),
                Value<bool> canReply = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryNotificationsCompanion.insert(
                pairId: pairId,
                id: id,
                payload: payload,
                postedAt: postedAt,
                keyHash: keyHash,
                canReply: canReply,
                dismissed: dismissed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryNotificationsTable, NotificationRow>(table),
                  BaseReferences<_$HistoryDatabase, $HistoryNotificationsTable, NotificationRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistoryNotificationsTable,
      NotificationRow,
      $$HistoryNotificationsTableFilterComposer,
      $$HistoryNotificationsTableOrderingComposer,
      $$HistoryNotificationsTableAnnotationComposer,
      $$HistoryNotificationsTableCreateCompanionBuilder,
      $$HistoryNotificationsTableUpdateCompanionBuilder,
      (NotificationRow, BaseReferences<_$HistoryDatabase, $HistoryNotificationsTable, NotificationRow>),
      NotificationRow,
      PrefetchHooks Function()
    >;
typedef $$HistoryRepliesTableCreateCompanionBuilder =
    HistoryRepliesCompanion Function({
      required String pairId,
      required String id,
      required String notificationId,
      required String payload,
      required String status,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$HistoryRepliesTableUpdateCompanionBuilder =
    HistoryRepliesCompanion Function({
      Value<String> pairId,
      Value<String> id,
      Value<String> notificationId,
      Value<String> payload,
      Value<String> status,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$HistoryRepliesTableFilterComposer extends Composer<_$HistoryDatabase, $HistoryRepliesTable> {
  $$HistoryRepliesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notificationId =>
      $composableBuilder(column: $table.notificationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HistoryRepliesTableOrderingComposer extends Composer<_$HistoryDatabase, $HistoryRepliesTable> {
  $$HistoryRepliesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notificationId =>
      $composableBuilder(column: $table.notificationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HistoryRepliesTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistoryRepliesTable> {
  $$HistoryRepliesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId => $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get notificationId =>
      $composableBuilder(column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<String> get payload => $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HistoryRepliesTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistoryRepliesTable,
          ReplyRow,
          $$HistoryRepliesTableFilterComposer,
          $$HistoryRepliesTableOrderingComposer,
          $$HistoryRepliesTableAnnotationComposer,
          $$HistoryRepliesTableCreateCompanionBuilder,
          $$HistoryRepliesTableUpdateCompanionBuilder,
          (ReplyRow, BaseReferences<_$HistoryDatabase, $HistoryRepliesTable, ReplyRow>),
          ReplyRow,
          PrefetchHooks Function()
        > {
  $$HistoryRepliesTableTableManager(_$HistoryDatabase db, $HistoryRepliesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryRepliesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryRepliesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryRepliesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> notificationId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryRepliesCompanion(
                pairId: pairId,
                id: id,
                notificationId: notificationId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pairId,
                required String id,
                required String notificationId,
                required String payload,
                required String status,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HistoryRepliesCompanion.insert(
                pairId: pairId,
                id: id,
                notificationId: notificationId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryRepliesTable, ReplyRow>(table),
                  BaseReferences<_$HistoryDatabase, $HistoryRepliesTable, ReplyRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryRepliesTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistoryRepliesTable,
      ReplyRow,
      $$HistoryRepliesTableFilterComposer,
      $$HistoryRepliesTableOrderingComposer,
      $$HistoryRepliesTableAnnotationComposer,
      $$HistoryRepliesTableCreateCompanionBuilder,
      $$HistoryRepliesTableUpdateCompanionBuilder,
      (ReplyRow, BaseReferences<_$HistoryDatabase, $HistoryRepliesTable, ReplyRow>),
      ReplyRow,
      PrefetchHooks Function()
    >;
typedef $$HistoryDismissalsTableCreateCompanionBuilder =
    HistoryDismissalsCompanion Function({
      required String pairId,
      required String keyHash,
      required int at,
      Value<int> rowid,
    });
typedef $$HistoryDismissalsTableUpdateCompanionBuilder =
    HistoryDismissalsCompanion Function({Value<String> pairId, Value<String> keyHash, Value<int> at, Value<int> rowid});

class $$HistoryDismissalsTableFilterComposer extends Composer<_$HistoryDatabase, $HistoryDismissalsTable> {
  $$HistoryDismissalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));
}

class $$HistoryDismissalsTableOrderingComposer extends Composer<_$HistoryDatabase, $HistoryDismissalsTable> {
  $$HistoryDismissalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));
}

class $$HistoryDismissalsTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistoryDismissalsTable> {
  $$HistoryDismissalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId => $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get keyHash => $composableBuilder(column: $table.keyHash, builder: (column) => column);

  GeneratedColumn<int> get at => $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$HistoryDismissalsTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistoryDismissalsTable,
          DismissalRow,
          $$HistoryDismissalsTableFilterComposer,
          $$HistoryDismissalsTableOrderingComposer,
          $$HistoryDismissalsTableAnnotationComposer,
          $$HistoryDismissalsTableCreateCompanionBuilder,
          $$HistoryDismissalsTableUpdateCompanionBuilder,
          (DismissalRow, BaseReferences<_$HistoryDatabase, $HistoryDismissalsTable, DismissalRow>),
          DismissalRow,
          PrefetchHooks Function()
        > {
  $$HistoryDismissalsTableTableManager(_$HistoryDatabase db, $HistoryDismissalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryDismissalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryDismissalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryDismissalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<String> keyHash = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryDismissalsCompanion(pairId: pairId, keyHash: keyHash, at: at, rowid: rowid),
          createCompanionCallback:
              ({
                required String pairId,
                required String keyHash,
                required int at,
                Value<int> rowid = const Value.absent(),
              }) => HistoryDismissalsCompanion.insert(pairId: pairId, keyHash: keyHash, at: at, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryDismissalsTable, DismissalRow>(table),
                  BaseReferences<_$HistoryDatabase, $HistoryDismissalsTable, DismissalRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryDismissalsTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistoryDismissalsTable,
      DismissalRow,
      $$HistoryDismissalsTableFilterComposer,
      $$HistoryDismissalsTableOrderingComposer,
      $$HistoryDismissalsTableAnnotationComposer,
      $$HistoryDismissalsTableCreateCompanionBuilder,
      $$HistoryDismissalsTableUpdateCompanionBuilder,
      (DismissalRow, BaseReferences<_$HistoryDatabase, $HistoryDismissalsTable, DismissalRow>),
      DismissalRow,
      PrefetchHooks Function()
    >;
typedef $$HistoryPublishedTableCreateCompanionBuilder =
    HistoryPublishedCompanion Function({
      required String pairId,
      required String keyHash,
      required int at,
      Value<int> rowid,
    });
typedef $$HistoryPublishedTableUpdateCompanionBuilder =
    HistoryPublishedCompanion Function({Value<String> pairId, Value<String> keyHash, Value<int> at, Value<int> rowid});

class $$HistoryPublishedTableFilterComposer extends Composer<_$HistoryDatabase, $HistoryPublishedTable> {
  $$HistoryPublishedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));
}

class $$HistoryPublishedTableOrderingComposer extends Composer<_$HistoryDatabase, $HistoryPublishedTable> {
  $$HistoryPublishedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));
}

class $$HistoryPublishedTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistoryPublishedTable> {
  $$HistoryPublishedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId => $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get keyHash => $composableBuilder(column: $table.keyHash, builder: (column) => column);

  GeneratedColumn<int> get at => $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$HistoryPublishedTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistoryPublishedTable,
          PublishedRow,
          $$HistoryPublishedTableFilterComposer,
          $$HistoryPublishedTableOrderingComposer,
          $$HistoryPublishedTableAnnotationComposer,
          $$HistoryPublishedTableCreateCompanionBuilder,
          $$HistoryPublishedTableUpdateCompanionBuilder,
          (PublishedRow, BaseReferences<_$HistoryDatabase, $HistoryPublishedTable, PublishedRow>),
          PublishedRow,
          PrefetchHooks Function()
        > {
  $$HistoryPublishedTableTableManager(_$HistoryDatabase db, $HistoryPublishedTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryPublishedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryPublishedTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryPublishedTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<String> keyHash = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryPublishedCompanion(pairId: pairId, keyHash: keyHash, at: at, rowid: rowid),
          createCompanionCallback:
              ({
                required String pairId,
                required String keyHash,
                required int at,
                Value<int> rowid = const Value.absent(),
              }) => HistoryPublishedCompanion.insert(pairId: pairId, keyHash: keyHash, at: at, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryPublishedTable, PublishedRow>(table),
                  BaseReferences<_$HistoryDatabase, $HistoryPublishedTable, PublishedRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryPublishedTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistoryPublishedTable,
      PublishedRow,
      $$HistoryPublishedTableFilterComposer,
      $$HistoryPublishedTableOrderingComposer,
      $$HistoryPublishedTableAnnotationComposer,
      $$HistoryPublishedTableCreateCompanionBuilder,
      $$HistoryPublishedTableUpdateCompanionBuilder,
      (PublishedRow, BaseReferences<_$HistoryDatabase, $HistoryPublishedTable, PublishedRow>),
      PublishedRow,
      PrefetchHooks Function()
    >;
typedef $$HistorySearchTableCreateCompanionBuilder =
    HistorySearchCompanion Function({
      required String pairId,
      required String id,
      required String content,
      Value<int> rowid,
    });
typedef $$HistorySearchTableUpdateCompanionBuilder =
    HistorySearchCompanion Function({Value<String> pairId, Value<String> id, Value<String> content, Value<int> rowid});

class $$HistorySearchTableFilterComposer extends Composer<_$HistoryDatabase, $HistorySearchTable> {
  $$HistorySearchTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$HistorySearchTableOrderingComposer extends Composer<_$HistoryDatabase, $HistorySearchTable> {
  $$HistorySearchTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$HistorySearchTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistorySearchTable> {
  $$HistorySearchTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairId => $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$HistorySearchTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistorySearchTable,
          SearchRow,
          $$HistorySearchTableFilterComposer,
          $$HistorySearchTableOrderingComposer,
          $$HistorySearchTableAnnotationComposer,
          $$HistorySearchTableCreateCompanionBuilder,
          $$HistorySearchTableUpdateCompanionBuilder,
          (SearchRow, BaseReferences<_$HistoryDatabase, $HistorySearchTable, SearchRow>),
          SearchRow,
          PrefetchHooks Function()
        > {
  $$HistorySearchTableTableManager(_$HistoryDatabase db, $HistorySearchTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistorySearchTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistorySearchTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistorySearchTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistorySearchCompanion(pairId: pairId, id: id, content: content, rowid: rowid),
          createCompanionCallback:
              ({
                required String pairId,
                required String id,
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => HistorySearchCompanion.insert(pairId: pairId, id: id, content: content, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistorySearchTable, SearchRow>(table),
                  BaseReferences<_$HistoryDatabase, $HistorySearchTable, SearchRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistorySearchTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistorySearchTable,
      SearchRow,
      $$HistorySearchTableFilterComposer,
      $$HistorySearchTableOrderingComposer,
      $$HistorySearchTableAnnotationComposer,
      $$HistorySearchTableCreateCompanionBuilder,
      $$HistorySearchTableUpdateCompanionBuilder,
      (SearchRow, BaseReferences<_$HistoryDatabase, $HistorySearchTable, SearchRow>),
      SearchRow,
      PrefetchHooks Function()
    >;

class $HistoryDatabaseManager {
  final _$HistoryDatabase _db;
  $HistoryDatabaseManager(this._db);
  $$HistoryNotificationsTableTableManager get historyNotifications =>
      $$HistoryNotificationsTableTableManager(_db, _db.historyNotifications);
  $$HistoryRepliesTableTableManager get historyReplies => $$HistoryRepliesTableTableManager(_db, _db.historyReplies);
  $$HistoryDismissalsTableTableManager get historyDismissals =>
      $$HistoryDismissalsTableTableManager(_db, _db.historyDismissals);
  $$HistoryPublishedTableTableManager get historyPublished =>
      $$HistoryPublishedTableTableManager(_db, _db.historyPublished);
  $$HistorySearchTableTableManager get historySearch => $$HistorySearchTableTableManager(_db, _db.historySearch);
}
