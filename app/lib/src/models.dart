import 'dart:convert';

DateTime _date(Object? value, [DateTime? fallback]) {
  if (value is String) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.credit,
    this.avatarAsset,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  int credit;
  String? avatarAsset;
  DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'credit': credit,
        'avatarAsset': avatarAsset,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        id: json['id']! as String,
        name: json['name']! as String,
        credit: (json['credit'] as num?)?.toInt() ?? 0,
        avatarAsset: json['avatarAsset'] as String?,
        updatedAt: _date(json['updatedAt']),
      );
}

class Mission {
  Mission({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.credit,
    required this.createdAt,
    this.completed = false,
    this.starred = false,
    this.completedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String ownerId;
  String title;
  String description;
  int credit;
  final DateTime createdAt;
  bool completed;
  bool starred;
  DateTime? completedAt;
  DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'credit': credit,
        'createdAt': createdAt.toIso8601String(),
        'completed': completed,
        'starred': starred,
        'completedAt': completedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Mission.fromJson(Map<String, Object?> json) {
    final DateTime createdAt = _date(json['createdAt']);
    return Mission(
      id: json['id']! as String,
      ownerId: json['ownerId']! as String,
      title: json['title']! as String,
      description: json['description'] as String? ?? '',
      credit: (json['credit'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      completed: json['completed'] as bool? ?? false,
      starred: json['starred'] as bool? ?? false,
      completedAt:
          json['completedAt'] == null ? null : _date(json['completedAt']),
      updatedAt: _date(json['updatedAt'], createdAt),
    );
  }
}

class Reward {
  Reward({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.cost,
    required this.createdAt,
    this.imageAsset,
    this.available = true,
    this.starred = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String ownerId;
  String title;
  String description;
  int cost;
  final DateTime createdAt;
  String? imageAsset;
  bool available;
  bool starred;
  DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'cost': cost,
        'createdAt': createdAt.toIso8601String(),
        'imageAsset': imageAsset,
        'available': available,
        'starred': starred,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Reward.fromJson(Map<String, Object?> json) {
    final DateTime createdAt = _date(json['createdAt']);
    return Reward(
      id: json['id']! as String,
      ownerId: json['ownerId']! as String,
      title: json['title']! as String,
      description: json['description'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      imageAsset: json['imageAsset'] as String?,
      available: json['available'] as bool? ?? true,
      starred: json['starred'] as bool? ?? false,
      updatedAt: _date(json['updatedAt'], createdAt),
    );
  }
}

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.ownerId,
    required this.rewardTitle,
    required this.description,
    required this.cost,
    required this.acquiredAt,
    this.imageAsset,
    this.used = false,
    this.usedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? acquiredAt;

  final String id;
  final String ownerId;
  String rewardTitle;
  String description;
  final int cost;
  final DateTime acquiredAt;
  String? imageAsset;
  bool used;
  DateTime? usedAt;
  DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ownerId': ownerId,
        'rewardTitle': rewardTitle,
        'description': description,
        'cost': cost,
        'acquiredAt': acquiredAt.toIso8601String(),
        'imageAsset': imageAsset,
        'used': used,
        'usedAt': usedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, Object?> json) {
    final DateTime acquiredAt = _date(json['acquiredAt']);
    return InventoryItem(
      id: json['id']! as String,
      ownerId: json['ownerId']! as String,
      rewardTitle: json['rewardTitle']! as String,
      description: json['description'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      acquiredAt: acquiredAt,
      imageAsset: json['imageAsset'] as String?,
      used: json['used'] as bool? ?? false,
      usedAt: json['usedAt'] == null ? null : _date(json['usedAt']),
      updatedAt: _date(json['updatedAt'], acquiredAt),
    );
  }
}

class PointEntry {
  PointEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int amount;
  final String reason;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PointEntry.fromJson(Map<String, Object?> json) => PointEntry(
        id: json['id']! as String,
        userId: json['userId']! as String,
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        createdAt: _date(json['createdAt']),
      );
}

class Tombstone {
  Tombstone({
    required this.entity,
    required this.id,
    required this.deletedAt,
  });

  final String entity;
  final String id;
  final DateTime deletedAt;

  String get key => '$entity:$id';

  Map<String, Object?> toJson() => <String, Object?>{
        'entity': entity,
        'id': id,
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory Tombstone.fromJson(Map<String, Object?> json) => Tombstone(
        entity: json['entity']! as String,
        id: json['id']! as String,
        deletedAt: _date(json['deletedAt']),
      );
}

class AppSettings {
  const AppSettings({
    this.webDavUrl = '',
    this.webDavUsername = '',
    this.webDavPassword = '',
    this.webDavRemoteDirectory = 'RainbowCats',
    this.webDavFileName = 'rainbow-cats-data.json',
    this.autoSync = false,
    this.serverUrl = '',
    this.serverToken = '',
  });

  final String webDavUrl;
  final String webDavUsername;
  final String webDavPassword;
  final String webDavRemoteDirectory;
  final String webDavFileName;
  final bool autoSync;
  final String serverUrl;
  final String serverToken;

  bool get hasWebDav => webDavUrl.trim().isNotEmpty;

  AppSettings copyWith({
    String? webDavUrl,
    String? webDavUsername,
    String? webDavPassword,
    String? webDavRemoteDirectory,
    String? webDavFileName,
    bool? autoSync,
    String? serverUrl,
    String? serverToken,
  }) =>
      AppSettings(
        webDavUrl: webDavUrl ?? this.webDavUrl,
        webDavUsername: webDavUsername ?? this.webDavUsername,
        webDavPassword: webDavPassword ?? this.webDavPassword,
        webDavRemoteDirectory:
            webDavRemoteDirectory ?? this.webDavRemoteDirectory,
        webDavFileName: webDavFileName ?? this.webDavFileName,
        autoSync: autoSync ?? this.autoSync,
        serverUrl: serverUrl ?? this.serverUrl,
        serverToken: serverToken ?? this.serverToken,
      );

  Map<String, Object?> toJson({bool includeSecrets = true}) => <String, Object?>{
        'webDavUrl': webDavUrl,
        'webDavUsername': webDavUsername,
        if (includeSecrets) 'webDavPassword': webDavPassword,
        'webDavRemoteDirectory': webDavRemoteDirectory,
        'webDavFileName': webDavFileName,
        'autoSync': autoSync,
        'serverUrl': serverUrl,
        if (includeSecrets) 'serverToken': serverToken,
      };

  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
        webDavUrl: json['webDavUrl'] as String? ?? '',
        webDavUsername: json['webDavUsername'] as String? ?? '',
        webDavPassword: json['webDavPassword'] as String? ?? '',
        webDavRemoteDirectory:
            json['webDavRemoteDirectory'] as String? ?? 'RainbowCats',
        webDavFileName:
            json['webDavFileName'] as String? ?? 'rainbow-cats-data.json',
        autoSync: json['autoSync'] as bool? ?? false,
        serverUrl: json['serverUrl'] as String? ?? '',
        serverToken: json['serverToken'] as String? ?? '',
      );
}

class ActionResult {
  const ActionResult(this.ok, this.message);

  final bool ok;
  final String message;

  static const ActionResult success = ActionResult(true, '操作成功');
}

class RainbowSnapshot {
  RainbowSnapshot({
    required this.currentUserId,
    required this.users,
    required this.missions,
    required this.rewards,
    required this.inventory,
    required this.pointEntries,
    required this.tombstones,
    required this.modifiedAt,
    this.settings = const AppSettings(),
  });

  final String currentUserId;
  final List<UserProfile> users;
  final List<Mission> missions;
  final List<Reward> rewards;
  final List<InventoryItem> inventory;
  final List<PointEntry> pointEntries;
  final List<Tombstone> tombstones;
  final DateTime modifiedAt;
  final AppSettings settings;

  String encode({bool includeSettings = true, bool includeSecrets = true}) =>
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema': 2,
        'currentUserId': currentUserId,
        'modifiedAt': modifiedAt.toIso8601String(),
        'users': users.map((UserProfile value) => value.toJson()).toList(),
        'missions': missions.map((Mission value) => value.toJson()).toList(),
        'rewards': rewards.map((Reward value) => value.toJson()).toList(),
        'inventory': inventory
            .map((InventoryItem value) => value.toJson())
            .toList(),
        'pointEntries': pointEntries
            .map((PointEntry value) => value.toJson())
            .toList(),
        'tombstones':
            tombstones.map((Tombstone value) => value.toJson()).toList(),
        if (includeSettings)
          'settings': settings.toJson(includeSecrets: includeSecrets),
      });

  factory RainbowSnapshot.decode(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('根节点不是对象');
    }
    final Map<String, Object?> map = Map<String, Object?>.from(decoded);

    List<Map<String, Object?>> rows(String key) {
      final Object? value = map[key];
      if (value == null) return <Map<String, Object?>>[];
      if (value is! List) throw FormatException('$key 不是数组');
      return value
          .map((Object? item) {
            if (item is! Map) throw FormatException('$key 包含无效记录');
            return Map<String, Object?>.from(item);
          })
          .toList();
    }

    final Object? rawSettings = map['settings'];
    final AppSettings settings = rawSettings is Map
        ? AppSettings.fromJson(Map<String, Object?>.from(rawSettings))
        : const AppSettings();
    final List<UserProfile> users = rows('users').map(UserProfile.fromJson).toList();
    if (users.isEmpty) throw const FormatException('用户数据为空');
    final String currentUserId = map['currentUserId'] as String? ?? users.first.id;

    return RainbowSnapshot(
      currentUserId: currentUserId,
      users: users,
      missions: rows('missions').map(Mission.fromJson).toList(),
      rewards: rows('rewards').map(Reward.fromJson).toList(),
      inventory: rows('inventory').map(InventoryItem.fromJson).toList(),
      pointEntries: rows('pointEntries').map(PointEntry.fromJson).toList(),
      tombstones: rows('tombstones').map(Tombstone.fromJson).toList(),
      modifiedAt: _date(map['modifiedAt']),
      settings: settings,
    );
  }
}
