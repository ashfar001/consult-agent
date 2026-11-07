import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/session_manager.dart';
import 'update_controller.dart';

class AgentUpdateNotice extends ConsumerWidget {
  const AgentUpdateNotice({super.key, required this.authBusy});

  final bool authBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(agentUpdateProvider);
    if (update == null) return const SizedBox.shrink();

    final release = update.release;
    final error = update.error;
    final controller = ref.read(agentUpdateProvider.notifier);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    if (update.checking) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Checking for updates…',
          textAlign: TextAlign.center,
          style: style,
        ),
      );
    }
    if (release == null && error == null) return const SizedBox.shrink();
    final sessionBusy = ref.watch(
      sessionManagerProvider.select(
        (session) =>
            session.hasSession || session.status == TrackStatus.workdayEnded,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (release != null)
            Text(
              'ConsultAgent v${release.version} is available.',
              style: style,
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SelectableText(
                error,
                textAlign: TextAlign.center,
                style: style?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          if (update.installing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: update.progress),
            const SizedBox(height: 4),
            Text(
              update.restarting
                  ? 'Restarting ConsultAgent…'
                  : update.progress == null
                  ? 'Preparing the update…'
                  : 'Downloading… ${(update.progress! * 100).round()}%',
              style: style,
            ),
          ] else
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (release != null)
                  OutlinedButton(
                    onPressed: authBusy || sessionBusy
                        ? null
                        : controller.install,
                    child: const Text('Update now'),
                  )
                else
                  OutlinedButton(
                    onPressed: controller.check,
                    child: const Text('Check again'),
                  ),
                TextButton(
                  onPressed: controller.openReleasesPage,
                  child: const Text('Releases page'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
