import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotube/models/offline_playlist.dart';
import 'package:spotube/services/kv_store/kv_store.dart';
import 'package:uuid/uuid.dart';

/// Device-only playlists for already downloaded music.
/// No audio files are moved, renamed, uploaded, or duplicated.
class OfflinePlaylistsNotifier extends Notifier<List<OfflinePlaylist>> {
  static const _storageKey = 'offline_playlists_v1';

  @override
  List<OfflinePlaylist> build() {
    unawaited(_restore());
    return const [];
  }

  Future<void> _restore() async {
    final raw = KVStoreService.sharedPreferences.getString(_storageKey);
    if (raw != null) state = OfflinePlaylist.listFromJson(raw);
  }

  Future<void> _persist() => KVStoreService.sharedPreferences.setString(
    _storageKey,
    OfflinePlaylist.listToJson(state),
  );

  Future<void> create(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    final now = DateTime.now();
    state = [
      ...state,
      OfflinePlaylist(
        id: const Uuid().v4(),
        name: value,
        trackPaths: const [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await _persist();
  }

  Future<void> delete(String playlistId) async {
    state = state.where((playlist) => playlist.id != playlistId).toList();
    await _persist();
  }

  Future<void> addTracks(String playlistId, Iterable<String> paths) async {
    await _update(playlistId, (playlist) {
      final known = playlist.trackPaths.toSet();
      final additions = <String>[];
      for (final path in paths) {
        if (known.add(path)) additions.add(path);
      }
      return playlist.copyWith(
        trackPaths: [...playlist.trackPaths, ...additions],
      );
    });
  }

  Future<void> removeTrack(String playlistId, String path) => _update(
    playlistId,
    (playlist) => playlist.copyWith(
      trackPaths: playlist.trackPaths.where((item) => item != path).toList(),
    ),
  );

  /// Applies Flutter's ReorderableListView index convention.
  Future<void> reorder(String playlistId, int oldIndex, int newIndex) async {
    await _update(playlistId, (playlist) {
      final paths = [...playlist.trackPaths];
      if (oldIndex < 0 || oldIndex >= paths.length) return playlist;
      if (oldIndex < newIndex) newIndex -= 1;
      final moved = paths.removeAt(oldIndex);
      paths.insert(newIndex.clamp(0, paths.length).toInt(), moved);
      return playlist.copyWith(trackPaths: paths);
    });
  }

  Future<void> _update(
    String playlistId,
    OfflinePlaylist Function(OfflinePlaylist playlist) transform,
  ) async {
    final now = DateTime.now();
    state = state
        .map(
          (playlist) => playlist.id == playlistId
              ? transform(playlist).copyWith(updatedAt: now)
              : playlist,
        )
        .toList();
    await _persist();
  }
}

final offlinePlaylistsProvider =
    NotifierProvider<OfflinePlaylistsNotifier, List<OfflinePlaylist>>(
      OfflinePlaylistsNotifier.new,
    );
