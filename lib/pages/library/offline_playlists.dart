import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as material;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/button/back_button.dart';
import 'package:spotube/components/titlebar/titlebar.dart';
import 'package:spotube/components/track_tile/track_tile.dart';
import 'package:spotube/components/ui/button_tile.dart';
import 'package:spotube/models/metadata/metadata.dart';
import 'package:spotube/modules/library/offline_playlists/offline_playlist_dialogs.dart';
import 'package:spotube/modules/library/offline_playlists/offline_playlist_text.dart';
import 'package:spotube/provider/audio_player/audio_player.dart';
import 'package:spotube/provider/local_tracks/local_tracks_provider.dart';
import 'package:spotube/provider/offline_playlists/offline_playlists_provider.dart';
import 'package:spotube/provider/user_preferences/user_preferences_provider.dart';

/// Device-only ordered playlists made from music already in Downloads.
class OfflinePlaylistsPage extends HookConsumerWidget {
  const OfflinePlaylistsPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        material.MaterialPageRoute<void>(
          builder: (_) => const OfflinePlaylistsPage(),
        ),
      );

  @override
  Widget build(BuildContext context, ref) {
    final playlists = ref.watch(offlinePlaylistsProvider);
    final notifier = ref.read(offlinePlaylistsProvider.notifier);
    final downloadLocation = ref.watch(
      userPreferencesProvider.select(
        (preferences) => preferences.downloadLocation,
      ),
    );
    final localTracks =
        ref.watch(localTracksProvider).asData?.value[downloadLocation] ??
            const <SpotubeLocalTrackObject>[];
    final availablePaths = localTracks.map((track) => track.path).toSet();

    Future<void> create() async {
      final name = await showDialog<String>(
        context: context,
        builder: (context) => ToastLayer(
          child: OfflinePlaylistNameDialog(
            title: offlineText(
              context,
              'New offline playlist',
              'Nova lista offline',
            ),
          ),
        ),
      );
      if (name != null) await notifier.create(name);
    }

    return SafeArea(
      bottom: false,
      child: Scaffold(
        headers: [
          TitleBar(
            leading: const [BackButton()],
            title: Text(
              offlineText(context, 'Offline playlists', 'Listas offline'),
            ),
            backgroundColor: Colors.transparent,
            surfaceBlur: 0,
            trailing: [
              IconButton.ghost(
                icon: const Icon(SpotubeIcons.refresh),
                onPressed: () => ref.invalidate(localTracksProvider),
              ),
            ],
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                offlineText(
                  context,
                  'Create lists from music already downloaded to this phone. The order is saved locally.',
                  'Cria listas com músicas já descarregadas neste telemóvel. A ordem fica guardada localmente.',
                ),
              ).muted().small(),
              const Gap(12),
              Button.primary(
                onPressed: create,
                leading: const Icon(SpotubeIcons.add),
                child: Text(
                  offlineText(
                    context,
                    'New offline playlist',
                    'Nova lista offline',
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: playlists.isEmpty
                    ? Center(
                        child: Text(
                          offlineText(
                            context,
                            'No offline playlists yet.',
                            'Ainda não tens listas offline.',
                          ),
                        ).muted(),
                      )
                    : ListView.separated(
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final available = playlist.trackPaths
                              .where(availablePaths.contains)
                              .length;
                          return ButtonTile(
                            style: ButtonVariance.outline,
                            onPressed: () => Navigator.of(context).push(
                              material.MaterialPageRoute<void>(
                                builder: (_) => OfflinePlaylistDetailsPage(
                                  playlistId: playlist.id,
                                ),
                              ),
                            ),
                            leading: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(SpotubeIcons.playlist),
                            ),
                            title: Text(playlist.name),
                            subtitle: Text(
                              offlineText(
                                context,
                                '$available of ${playlist.trackPaths.length} songs available',
                                '$available de ${playlist.trackPaths.length} músicas disponíveis',
                              ),
                            ).muted(),
                            trailing: IconButton.destructive(
                              icon: const Icon(SpotubeIcons.trash),
                              onPressed: () => notifier.delete(playlist.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflinePlaylistDetailsPage extends HookConsumerWidget {
  const OfflinePlaylistDetailsPage({super.key, required this.playlistId});

  final String playlistId;

  Future<void> _play(
    WidgetRef ref,
    List<SpotubeLocalTrackObject> tracks, {
    SpotubeLocalTrackObject? current,
  }) async {
    if (tracks.isEmpty) return;
    final state = ref.read(audioPlayerProvider);
    final player = ref.read(audioPlayerProvider.notifier);
    final selected = current ?? tracks.first;
    if (!state.containsTracks(tracks)) {
      await player.load(
        tracks,
        initialIndex: tracks.indexWhere((track) => track.path == selected.path),
        autoPlay: true,
      );
    } else if (state.activeTrack?.id != selected.id) {
      await player.jumpToTrack(selected);
    }
  }

  @override
  Widget build(BuildContext context, ref) {
    final playlist = ref
        .watch(offlinePlaylistsProvider)
        .firstWhereOrNull((playlist) => playlist.id == playlistId);
    final notifier = ref.read(offlinePlaylistsProvider.notifier);
    final downloadLocation = ref.watch(
      userPreferencesProvider.select(
        (preferences) => preferences.downloadLocation,
      ),
    );
    final localTracksState = ref.watch(localTracksProvider);

    if (playlist == null) {
      return SafeArea(
        child: Scaffold(
          headers: [
            TitleBar(
              leading: const [BackButton()],
              title: Text(
                offlineText(context, 'Offline playlist', 'Lista offline'),
              ),
            ),
          ],
          child: Center(
            child: Text(
              offlineText(
                context,
                'Playlist not found.',
                'Lista não encontrada.',
              ),
            ),
          ),
        ),
      );
    }

    final downloadedTracks = localTracksState.asData?.value[downloadLocation] ??
        const <SpotubeLocalTrackObject>[];
    final byPath = {for (final track in downloadedTracks) track.path: track};
    final playableTracks =
        playlist.trackPaths.map((path) => byPath[path]).nonNulls.toList();
    final playerState = ref.watch(audioPlayerProvider);
    final isCurrentList =
        playableTracks.isNotEmpty && playerState.containsTracks(playableTracks);

    Future<void> addTracks() async {
      if (localTracksState.isLoading) return;
      final selected = await showDialog<List<String>>(
        context: context,
        builder: (context) => ToastLayer(
          child: OfflineTrackPickerDialog(
            tracks: downloadedTracks,
            existingTrackPaths: playlist.trackPaths.toSet(),
          ),
        ),
      );
      if (selected != null && selected.isNotEmpty) {
        await notifier.addTracks(playlist.id, selected);
      }
    }

    return SafeArea(
      bottom: false,
      child: Scaffold(
        headers: [
          TitleBar(
            leading: const [BackButton()],
            title: Text(playlist.name),
            backgroundColor: Colors.transparent,
            surfaceBlur: 0,
            trailing: [
              IconButton.ghost(
                icon: const Icon(SpotubeIcons.refresh),
                onPressed: () => ref.invalidate(localTracksProvider),
              ),
            ],
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.primary(
                        onPressed: playableTracks.isEmpty || isCurrentList
                            ? null
                            : () => _play(ref, playableTracks),
                        icon: Icon(
                          isCurrentList
                              ? SpotubeIcons.pause
                              : SpotubeIcons.play,
                        ),
                      ),
                      const Gap(8),
                      IconButton.outline(
                        onPressed: playableTracks.isEmpty
                            ? null
                            : () => ref.read(audioPlayerProvider.notifier).load(
                                  playableTracks.shuffled(),
                                  initialIndex: 0,
                                  autoPlay: true,
                                ),
                        icon: const Icon(SpotubeIcons.shuffle),
                      ),
                      const Spacer(),
                      Button.secondary(
                        onPressed: addTracks,
                        leading: const Icon(SpotubeIcons.add),
                        child: Text(
                          offlineText(
                            context,
                            'Add songs',
                            'Adicionar músicas',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    offlineText(
                      context,
                      'Hold the handle and drag a song to change the playback order.',
                      'Mantém o ícone premido e arrasta uma música para mudar a ordem de reprodução.',
                    ),
                  ).xSmall().muted(),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: localTracksState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : playlist.trackPaths.isEmpty
                      ? Center(
                          child: Text(
                            offlineText(
                              context,
                              'Add downloaded songs to this playlist.',
                              'Adiciona músicas descarregadas a esta lista.',
                            ),
                          ).muted(),
                        )
                      : material.ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 180),
                          itemCount: playlist.trackPaths.length,
                          onReorder: (oldIndex, newIndex) =>
                              notifier.reorder(playlist.id, oldIndex, newIndex),
                          itemBuilder: (context, index) {
                            final path = playlist.trackPaths[index];
                            final track = byPath[path];
                            if (track == null) {
                              return ButtonTile(
                                key: ValueKey(path),
                                style: ButtonVariance.destructive,
                                leading: material
                                    .ReorderableDelayedDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(SpotubeIcons.dragHandle),
                                  ),
                                ),
                                title: Text(
                                  offlineText(
                                    context,
                                    'File unavailable',
                                    'Ficheiro indisponível',
                                  ),
                                ),
                                subtitle: Text(
                                  path,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ).muted(),
                                trailing: IconButton.destructive(
                                  icon: const Icon(SpotubeIcons.trash),
                                  onPressed: () =>
                                      notifier.removeTrack(playlist.id, path),
                                ),
                              );
                            }
                            return Container(
                              key: ValueKey(path),
                              child: TrackTile(
                                playlist: playerState,
                                index: index,
                                track: track,
                                onTap: () =>
                                    _play(ref, playableTracks, current: track),
                                leadingActions: [
                                  IconButton.destructive(
                                    size: ButtonSize.small,
                                    icon: const Icon(SpotubeIcons.trash),
                                    onPressed: () =>
                                        notifier.removeTrack(playlist.id, path),
                                  ),
                                  material.ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(SpotubeIcons.dragHandle),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
