import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum VmfsTransitionKind {
  slide,
  fade,
  scale,
}

const Duration _forwardDuration = Duration(milliseconds: 280);
const Duration _reverseDuration = Duration(milliseconds: 240);

Page<T> buildVmfsPage<T>({
  required LocalKey key,
  required Widget child,
  VmfsTransitionKind kind = VmfsTransitionKind.slide,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: _forwardDuration,
    reverseTransitionDuration: _reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      return _buildTransition(
        animation: animation,
        kind: kind,
        child: page,
      );
    },
  );
}

Route<T> vmfsSlideRoute<T>({
  required Widget Function(BuildContext) builder,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: _forwardDuration,
    reverseTransitionDuration: _reverseDuration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildTransition(animation: animation, kind: VmfsTransitionKind.slide, child: child);
    },
  );
}

Widget _buildTransition({
  required Animation<double> animation,
  required VmfsTransitionKind kind,
  required Widget child,
}) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

  return switch (kind) {
    VmfsTransitionKind.fade => FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: child,
      ),
    VmfsTransitionKind.scale => FadeTransition(
        opacity: Tween<double>(begin: 0.92, end: 1).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      ),
    VmfsTransitionKind.slide => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      ),
  };
}

extension VmfsNavigatorContext on BuildContext {
  Future<T?> pushVmfsScreen<T>(Widget screen) {
    return Navigator.of(this).push<T>(vmfsSlideRoute<T>(builder: (_) => screen));
  }
}
