import 'package:flutter/material.dart';

import '../feedback/vmfs_tap_feedback.dart';

/// Wraps tappable UI with a quick scale animation and tap feedback.
class VmfsTap extends StatefulWidget {
  const VmfsTap({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 12,
    this.enabled = true,
    this.primaryFeedback = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enabled;
  final bool primaryFeedback;

  @override
  State<VmfsTap> createState() => _VmfsTapState();
}

class _VmfsTapState extends State<VmfsTap> {
  bool _pressed = false;

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) {
      return;
    }

    widget.onTap!();

    if (widget.primaryFeedback) {
      VmfsTapFeedback.playPrimary();
    } else {
      VmfsTapFeedback.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.enabled && widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? _handleTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
