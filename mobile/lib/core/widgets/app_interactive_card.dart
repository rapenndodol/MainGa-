import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pembungkus kartu dengan animasi masuk bertahap dan umpan balik tekan.
///
/// Animasi masuk memakai fade + geser 10dp selama 220ms. [index] memberi jeda
/// bertahap yang dibatasi agar daftar panjang tidak terasa lambat. Semua gerak
/// dihentikan saat pengguna mengaktifkan reduce motion.
class AppInteractiveCard extends StatefulWidget {
  final Widget child;
  final int index;
  final bool enablePressScale;

  const AppInteractiveCard({
    super.key,
    required this.child,
    this.index = 0,
    this.enablePressScale = true,
  });

  @override
  State<AppInteractiveCard> createState() => _AppInteractiveCardState();
}

class _AppInteractiveCardState extends State<AppInteractiveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    final int delay = widget.index.clamp(0, 6) * 28;
    final int total = AppMotion.base.inMilliseconds + delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    final double start = total == 0 ? 0.0 : delay / total;
    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: AppMotion.curve),
    );
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value < 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!widget.enablePressScale || _reduceMotion) return;
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
