import 'dart:convert';

/// A playlist built from music files that already exist on the device.
class OfflinePlaylist {
  const OfflinePlaylist({
    required this.id,
    required this.name,
    required this.trackPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfflinePlaylist copyWith({
    String? name,
    List<String>? trackPaths,
    DateTime? updatedAt,
  }) {
    return OfflinePlaylist(
      id: id,
      name: name ?? this.name,
      trackPaths: trackPaths ?? this.trackPaths,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackPaths': trackPaths,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory OfflinePlaylist.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return OfflinePlaylist(
      id: json['id'] as String,
      name: (json['name'] as String).trim(),
      trackPaths: List<String>.from(json['trackPaths'] as List? ?? const []),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }

  static List<OfflinePlaylist> listFromJson(String source) {
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(OfflinePlaylist.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String listToJson(Iterable<OfflinePlaylist> playlists) =>
      jsonEncode(playlists.map((playlist) => playlist.toJson()).toList());
}
