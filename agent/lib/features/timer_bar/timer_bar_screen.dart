import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/hour_limits.dart';
import '../../services/bar_hide_logic.dart';
import '../../services/session_manager.dart';
import '../../services/timer_dock_preferences.dart';

/// The work controls shown in the agent's edge dock.
class TimerBarScreen extends ConsumerWidget {
  const TimerBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionManagerProvider);
    final online = ref.watch(syncOnlineProvider).value ?? true;
    final flow = ref.read(flowCoordinatorProvider);
    return ValueListenableBuilder(
      valueListenable: ref.watch(windowServiceProvider).dockEdge,
      builder: (context, edge, _) => TimerDockView(
        session: session,
        online: online,
        edge: edge,
        onHide: flow.collapseBar,
        onBreak: flow.askBreak,
        onUpload: flow.openUpload,
        onEndWork: flow.openEndWork,
        onMove: () => flow.moveDock(edge.opposite),
      ),
    );
  }
}

class TimerDockView extends StatelessWidget {
  const TimerDockView({
    super.key,
    required this.session,
    required this.online,
    required this.edge,
    required this.onHide,
    required this.onBreak,
    required this.onUpload,
    required this.onEndWork,
    required this.onMove,
  });

  final SessionState session;
  final bool online;
  final DockEdge edge;
  final VoidCallback onHide;
  final VoidCallback onBreak;
  final VoidCallback onUpload;
  final VoidCallback onEndWork;
  final VoidCallback onMove;

  static const _ink = Color(0xFF272727);
  static const _muted = Color(0xFF66696F);
  static const _line = Color(0xFFDCDDE1);
  static const _surface = Colors.white;
  static const _soft = Color(0xFFF3F4F5);

  @override
  Widget build(BuildContext context) {
    final usage = session.usage;
    final idle = session.status == TrackStatus.idle;
    final overrun = usage?.level == UsageLevel.over;
    final accent = switch ((online, idle, session.overtime, usage?.level)) {
      (false, _, _, _) => _muted,
      (_, true, _, _) => AppColors.warning,
      (_, _, true, _) => _ink,
      (_, _, _, UsageLevel.over) => AppColors.danger,
      (_, _, _, UsageLevel.warning) => AppColors.warning,
      _ => AppColors.ok,
    };
    final hours = switch (usage) {
      _ when session.overtime => 'Overtime · Project hours are paused',
      null => '',
      _ when overrun => 'Overrun ${formatHm(usage.overrunSecs)}',
      _ => '${formatHm(usage.remainingSecs)} left',
    };
    final status = [
      if (idle) 'Idle · Timer paused',
      if (!online) 'Offline · Saved locally',
      if (online && !idle) 'Active',
    ].join('  /  ');
    final left = edge == DockEdge.left;
    final anchor = left ? Alignment.centerLeft : Alignment.centerRight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Allow for device pixel rounding at fractional Windows DPI.
        if (constraints.maxWidth <= timerDockTabWidth + 1) {
          return Semantics(
            label: 'Timer dock. $status. Hover or press Control Shift F11.',
            child: ColoredBox(color: accent),
          );
        }
        // Resize the actual window and reveal a fixed width panel from the
        // anchored edge, rather than squeezing the controls during animation.
        return ClipRect(
          child: OverflowBox(
            alignment: anchor,
            minWidth: timerDockWidth,
            maxWidth: timerDockWidth,
            minHeight: timerDockHeight,
            maxHeight: timerDockHeight,
            child: Material(
              color: _surface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _line),
                    ),
                  ),
                  Align(
                    alignment: anchor,
                    child: SizedBox(
                      width: timerDockTabWidth,
                      height: timerDockHeight,
                      child: ColoredBox(color: accent),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      left ? 16 : 11,
                      6,
                      left ? 11 : 16,
                      6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    session.project?.code,
                                    session.task?.title,
                                  ].nonNulls.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _DockButton(
                                icon: left
                                    ? Icons.chevron_left_rounded
                                    : Icons.chevron_right_rounded,
                                label: 'Hide',
                                onPressed: onHide,
                                quiet: true,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 16,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (hours.isNotEmpty) ...[
                                  TextSpan(
                                    text: hours,
                                    style: TextStyle(
                                      color: overrun && !session.overtime
                                          ? AppColors.danger
                                          : _ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' · '),
                                ],
                                TextSpan(
                                  text:
                                      'Today ${formatHm(session.todayActiveSecs)}',
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 30,
                          child: Row(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _DockButton(
                                  icon: Icons.free_breakfast_outlined,
                                  label: 'Break',
                                  onPressed: onBreak,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: _DockButton(
                                  icon: Icons.cloud_upload_outlined,
                                  label: 'Upload',
                                  onPressed: onUpload,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: _DockButton(
                                  icon: Icons.stop_circle_outlined,
                                  label: 'End work',
                                  onPressed: onEndWork,
                                  primary: true,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: _DockButton(
                                  icon: left
                                      ? Icons
                                            .keyboard_double_arrow_right_rounded
                                      : Icons
                                            .keyboard_double_arrow_left_rounded,
                                  label: left ? 'Move right' : 'Move left',
                                  onPressed: onMove,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.quiet = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool quiet;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style:
        TextButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: quiet ? 6 : 4),
          foregroundColor: primary ? Colors.white : TimerDockView._ink,
          backgroundColor: primary
              ? TimerDockView._ink
              : quiet
              ? Colors.transparent
              : TimerDockView._soft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: primary ? Colors.white : TimerDockView._ink)
                : BorderSide.none,
          ),
        ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
