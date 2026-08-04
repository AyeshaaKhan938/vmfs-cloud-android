import 'package:flutter/material.dart';

import '../feedback/vmfs_tap_feedback.dart';
import 'vmfs_tap.dart';

Future<void> _playTap({bool primary = false}) {
  return primary ? VmfsTapFeedback.playPrimary() : VmfsTapFeedback.play();
}

/// Wraps any tappable control with scale animation + tap feedback.
class VmfsInteractive extends StatelessWidget {
  const VmfsInteractive({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.primary = false,
    this.borderRadius = 12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool primary;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return VmfsTap(
      enabled: enabled,
      onTap: onTap,
      primaryFeedback: primary,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

class VmfsElevatedButton extends StatelessWidget {
  const VmfsElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed == null ? null : () {},
      style: style,
      child: child,
    );

    if (onPressed == null) {
      return button;
    }

    return VmfsInteractive(onTap: onPressed, child: IgnorePointer(child: button));
  }
}

class VmfsOutlinedButton extends StatelessWidget {
  const VmfsOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed == null ? null : () {},
      style: style,
      child: child,
    );

    if (onPressed == null) {
      return button;
    }

    return VmfsInteractive(onTap: onPressed, child: IgnorePointer(child: button));
  }
}

class VmfsTextButton extends StatelessWidget {
  const VmfsTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed == null ? null : () {},
      style: style,
      child: child,
    );

    if (onPressed == null) {
      return button;
    }

    return VmfsInteractive(onTap: onPressed, borderRadius: 8, child: IgnorePointer(child: button));
  }
}

class VmfsFilledButton extends StatelessWidget {
  const VmfsFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  })  : icon = null,
        label = null;

  const VmfsFilledButton.icon({
    super.key,
    required this.onPressed,
    required Widget this.icon,
    required Widget this.label,
    this.style,
  }) : child = null;

  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final Widget button = icon != null
        ? FilledButton.icon(
            onPressed: onPressed == null ? null : () {},
            style: style,
            icon: icon!,
            label: label!,
          )
        : FilledButton(
            onPressed: onPressed == null ? null : () {},
            style: style,
            child: child!,
          );

    if (onPressed == null) {
      return button;
    }

    return VmfsInteractive(onTap: onPressed, child: IgnorePointer(child: button));
  }
}

class VmfsIconButton extends StatelessWidget {
  const VmfsIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.style,
    this.padding,
    this.constraints,
  }) : _filled = false;

  const VmfsIconButton.filled({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.style,
    this.padding,
    this.constraints,
  }) : _filled = true;

  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final ButtonStyle? style;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final bool _filled;

  @override
  Widget build(BuildContext context) {
    final Widget button = _filled
        ? IconButton.filled(
            onPressed: onPressed == null ? null : () {},
            icon: icon,
            tooltip: tooltip,
            style: style,
            padding: padding,
            constraints: constraints,
          )
        : IconButton(
            onPressed: onPressed == null ? null : () {},
            icon: icon,
            tooltip: tooltip,
            style: style,
            padding: padding,
            constraints: constraints,
          );

    if (onPressed == null) {
      return button;
    }

    return VmfsInteractive(
      onTap: onPressed,
      borderRadius: 20,
      child: IgnorePointer(child: button),
    );
  }
}

class VmfsFloatingActionButton extends StatelessWidget {
  const VmfsFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
  })  : _icon = null,
        _label = null;

  const VmfsFloatingActionButton.extended({
    super.key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
  })  : child = null,
        _icon = icon,
        _label = label;

  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? _icon;
  final Widget? _label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget fab = _icon != null
        ? FloatingActionButton.extended(
            onPressed: onPressed == null ? null : () {},
            icon: _icon!,
            label: _label!,
            tooltip: tooltip,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            heroTag: heroTag,
          )
        : FloatingActionButton(
            onPressed: onPressed == null ? null : () {},
            tooltip: tooltip,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            heroTag: heroTag,
            child: child!,
          );

    if (onPressed == null) {
      return fab;
    }

    return VmfsInteractive(
      onTap: onPressed,
      borderRadius: 28,
      primary: true,
      child: IgnorePointer(child: fab),
    );
  }
}

/// Card + ListTile with tap scale and sound.
class VmfsTappableCard extends StatelessWidget {
  const VmfsTappableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return VmfsTap(
      enabled: onTap != null,
      onTap: onTap,
      borderRadius: 14,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Card(color: color, child: child),
      ),
    );
  }
}

/// Play feedback before executing an async/sync callback (lists, custom widgets).
Future<T?> vmfsRunTap<T>(VoidCallback action, {bool primary = false}) async {
  await _playTap(primary: primary);
  action();
  return null;
}
