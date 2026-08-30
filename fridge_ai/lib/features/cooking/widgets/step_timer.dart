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
                  // Eases toward each new second's value instead of
                  // snapping — the ring sweeps continuously rather than
                  // ticking once per second like the digits above it.
                  child: _AnimatedRingProgress(
                    value: progress.clamp(0, 1),
                    trackColor: theme.dividerColor,
                    valueColor: _finished ? AppColors.secondaryGreen : AppColors.primaryOrange,
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

/// Animates [CircularProgressIndicator]'s value smoothly from whatever it
/// last was to the new [value] — same "tween from the previous rendered
/// value" pattern as the cooking-mode step progress bar, needed because a
/// plain [TweenAnimationBuilder] would restart from 0 on every one-second
/// tick instead of continuing from where the ring currently is.
class _AnimatedRingProgress extends StatefulWidget {
  const _AnimatedRingProgress({
    required this.value,
    required this.trackColor,
    required this.valueColor,
  });

  final double value;
  final Color trackColor;
  final Color valueColor;

  @override
  State<_AnimatedRingProgress> createState() => _AnimatedRingProgressState();
}

class _AnimatedRingProgressState extends State<_AnimatedRingProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late Animation<double> _animation = AlwaysStoppedAnimation(widget.value);

  @override
  void initState() {
    super.initState();
    _animation = Tween(begin: widget.value, end: widget.value).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedRingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween(begin: _animation.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => CircularProgressIndicator(
        value: _animation.value,
        strokeWidth: 8,
        backgroundColor: widget.trackColor,
        valueColor: AlwaysStoppedAnimation(widget.valueColor),
      ),
    );
  }
}
