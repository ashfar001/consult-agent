import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/hour_limits.dart';
import '../../services/session_manager.dart';

/// The small always-on-top strip shown while working.
class TimerBarScreen extends ConsumerWidget {
  const TimerBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionManagerProvider);
    final online = ref.watch(syncOnlineProvider).value ?? true;
    final flow = ref.read(flowCoordinatorProvider);
    final usage = s.usage;
    final project = s.project;

    final Color dot;
    final String dotLabel;
    if (!online) {
      dot = AppColors.muted;
      dotLabel = 'Offline: time is saved and will sync';
    } else if (s.status == TrackStatus.idle) {
      dot = AppColors.warning;
      dotLabel = 'Idle: not counting';
    } else {
      dot = AppColors.ok;
      dotLabel = 'Active';
    }

    String hoursText;
    Color hoursColor = AppColors.muted;
    if (s.overtime) {
      hoursText = 'OVERTIME';
      hoursColor = AppColors.danger;
    } else if (usage == null) {
      hoursText = '';
    } else if (usage.level == UsageLevel.over) {
      hoursText = 'Overrun +${formatHm(usage.overrunSecs)}';
      hoursColor = AppColors.danger;
    } else {
      hoursText = '${formatHm(usage.remainingSecs)} left';
      if (usage.level == UsageLevel.warning) hoursColor = AppColors.warning;
    }

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // The top band is all that shows when the bar tucks away; its
          // colour tells active / idle / offline at a glance.
          Container(height: 6, color: dot),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 1.5),
                  right: BorderSide(color: AppColors.primary, width: 1.5),
                  bottom: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.only(left: 10, right: 2),
              child: Row(
                children: [
                  Expanded(
                    child: DragToMoveArea(
                      child: Row(
                        children: [
                          Tooltip(
                            message: dotLabel,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${project?.code ?? ''} · ${s.task?.title ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Today ${formatHm(s.todayActiveSecs)}',
                                      ),
                                      const TextSpan(text: '  ·  '),
                                      TextSpan(
                                        text: hoursText,
                                        style: TextStyle(
                                          color: hoursColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BarButton(
                    icon: Icons.free_breakfast_outlined,
                    tooltip: 'Lunch break',
                    onPressed: flow.askBreak,
                  ),
                  _BarButton(
                    icon: Icons.cloud_upload_outlined,
                    tooltip: 'Upload files',
                    onPressed: flow.openUpload,
                  ),
                  _BarButton(
                    icon: Icons.stop_circle_outlined,
                    tooltip: 'End work',
                    color: AppColors.danger,
                    onPressed: flow.openEndWork,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, color: color ?? AppColors.primary),
    tooltip: tooltip,
    iconSize: 24,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
  );
}
