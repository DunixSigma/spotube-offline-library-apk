import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:spotube/components/ui/button_tile.dart';
import 'package:spotube/models/metadata/metadata.dart';
import 'package:spotube/modules/library/offline_playlists/offline_playlist_text.dart';

class OfflinePlaylistNameDialog extends HookWidget {
  const OfflinePlaylistNameDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final invalid = useState(false);

    void save() {
      if (controller.text.trim().isEmpty) {
        invalid.value = true;
        return;
      }
      Navigator.of(context).pop(controller.text.trim());
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              placeholder: Text(
                offlineText(
                  context,
                  'For example, Gym',
                  'Por exemplo, Ginásio',
                ),
              ),
              onSubmitted: (_) => save(),
            ),
            if (invalid.value) ...[
              const Gap(8),
              Text(
                offlineText(context, 'Enter a name.', 'Indica um nome.'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.destructive,
                ),
              ).small(),
            ],
          ],
        ),
      ),
      actions: [
        Button.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(offlineText(context, 'Cancel', 'Cancelar')),
        ),
        Button.primary(
          onPressed: save,
          child: Text(offlineText(context, 'Create', 'Criar')),
        ),
      ],
    );
  }
}

class OfflineTrackPickerDialog extends HookConsumerWidget {
  const OfflineTrackPickerDialog({
    super.key,
    required this.tracks,
    required this.existingTrackPaths,
  });

  final List<SpotubeLocalTrackObject> tracks;
  final Set<String> existingTrackPaths;

  @override
  Widget build(BuildContext context, ref) {
    final selected = useState(<String>{});
    final available = tracks
        .where((track) => !existingTrackPaths.contains(track.path))
        .toList();

    void toggle(String path) {
      final next = {...selected.value};
      if (!next.add(path)) next.remove(path);
      selected.value = next;
    }

    return AlertDialog(
      title: Text(
        offlineText(
          context,
          'Add downloaded songs',
          'Adicionar músicas descarregadas',
        ),
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: available.isEmpty
            ? Center(
                child: Text(
                  offlineText(
                    context,
                    'There are no more downloaded songs to add.',
                    'Não existem mais músicas descarregadas para adicionar.',
                  ),
                  textAlign: TextAlign.center,
                ).muted(),
              )
            : ListView.separated(
                itemCount: available.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final track = available[index];
                  final checked = selected.value.contains(track.path);
                  return ButtonTile(
                    style: ButtonVariance.ghost,
                    onPressed: () => toggle(track.path),
                    leading: Checkbox(
                      state: checked
                          ? CheckboxState.checked
                          : CheckboxState.unchecked,
                      onChanged: (_) => toggle(track.path),
                    ),
                    title: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artists.map((artist) => artist.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).muted(),
                  );
                },
              ),
      ),
      actions: [
        Button.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(offlineText(context, 'Cancel', 'Cancelar')),
        ),
        Button.primary(
          onPressed: available.isEmpty
              ? null
              : () => Navigator.of(context).pop(selected.value.toList()),
          child: Text(
            offlineText(
              context,
              'Add ${selected.value.length}',
              'Adicionar ${selected.value.length}',
            ),
          ),
        ),
      ],
    );
  }
}
