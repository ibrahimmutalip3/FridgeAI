import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// A circular countdown timer that can be started directly from a cooking
/// step. Purely local (no persistence needed) — resets if the step is
/// revisited after completion.
class StepTimer extends StatefulWidget {
  const StepTimer({super.key, required this.seconds});

  final int seconds;

  @override
  State<StepTimer> createState() => _StepTimerState();
}

class _StepTimerState extends State<StepTimer> {
  late int _remaining = widget.seconds;
  Timer? _ticker;
  bool _running = false;
  bool _finished = false;

  @override
  void didUpdateWidget(covariant StepTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _ticker?.cancel();
      setState(() {
        _remaining = widget.seconds;
        _running = false;
        _finished = false;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }

    if (_finished || _remaining <= 0) {
      setState(() {
        _remaining = widget.seconds;
        _finished = false;
      });
    }

    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
          _finished = true;
        });
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.seconds;
      _running = false;
      _finished = false;
    });
  }

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.seconds == 0 ? 0.0 : 1 - (_remaining / widget.seconds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: SizedBox(
            width: 148,
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 148,
                  height: 148,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation(
                      _finished ? AppColors.secondaryGreen : AppColors.primaryOrange,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _format(_remaining),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      _finished
                          ? Icons.check_circle_rounded
                          : (_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: _finished ? AppColors.secondaryGreen : AppColors.primaryOrange,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_running || _remaining != widget.seconds)
          TextButton(
            onPressed: _reset,
            child: const Text('Reset timer'),
          )
        else
          Text(
            'Tap to start timer',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
