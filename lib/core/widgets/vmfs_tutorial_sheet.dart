import 'package:flutter/material.dart';

import '../onboarding/tutorial_step.dart';
import '../theme/vmfs_colors.dart';
import 'vmfs_interactive.dart';

Future<void> showVmfsTutorialSheet(
  BuildContext context, {
  required String title,
  required List<TutorialStep> steps,
  required Future<void> Function() onFinished,
  void Function(TutorialStep step)? onStepVisible,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (ctx) {
      return _VmfsTutorialSheet(
        title: title,
        steps: steps,
        onFinished: onFinished,
        onStepVisible: onStepVisible,
      );
    },
  );
}

class _VmfsTutorialSheet extends StatefulWidget {
  const _VmfsTutorialSheet({
    required this.title,
    required this.steps,
    required this.onFinished,
    this.onStepVisible,
  });

  final String title;
  final List<TutorialStep> steps;
  final Future<void> Function() onFinished;
  final void Function(TutorialStep step)? onStepVisible;

  @override
  State<_VmfsTutorialSheet> createState() => _VmfsTutorialSheetState();
}

class _VmfsTutorialSheetState extends State<_VmfsTutorialSheet> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyStep(_index));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notifyStep(int index) {
    widget.onStepVisible?.call(widget.steps[index]);
  }

  Future<void> _finish({required bool skipped}) async {
    await widget.onFinished();
    if (mounted) Navigator.pop(context);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _finish(skipped: false);
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    if (_index <= 0) return;

    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final isFirst = _index <= 0;
    final isLast = _index >= widget.steps.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VmfsColors.primaryDark),
                ),
              ),
              VmfsTextButton(onPressed: () => _finish(skipped: true), child: const Text('Skip tour')),
            ],
          ),
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.steps.length,
              onPageChanged: (value) {
                setState(() => _index = value);
                _notifyStep(value);
              },
              itemBuilder: (context, index) {
                final item = widget.steps[index];
                return Column(
                  children: [
                    if (item.kicker != null) ...[
                      Text(
                        item.kicker!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: VmfsColors.primaryDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: VmfsColors.primaryLight,
                      child: Icon(item.icon, size: 32, color: VmfsColors.primaryDark),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          item.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF555555)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _TutorialProgressIndicator(
            stepCount: widget.steps.length,
            currentIndex: _index,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: VmfsOutlinedButton(
                  onPressed: isFirst ? null : _previous,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: VmfsFilledButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Finish tour' : 'Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.kicker == null
                ? 'Step ${_index + 1} of ${widget.steps.length}'
                : '${step.kicker} · Step ${_index + 1} of ${widget.steps.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Dots for short tours; progress bar when many steps (avoids horizontal overflow).
class _TutorialProgressIndicator extends StatelessWidget {
  const _TutorialProgressIndicator({
    required this.stepCount,
    required this.currentIndex,
  });

  final int stepCount;
  final int currentIndex;

  static const int _maxDots = 8;

  @override
  Widget build(BuildContext context) {
    if (stepCount <= _maxDots) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(stepCount, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == currentIndex ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == currentIndex ? VmfsColors.primaryDark : VmfsColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (currentIndex + 1) / stepCount,
        minHeight: 6,
        backgroundColor: VmfsColors.primaryLight,
        color: VmfsColors.primaryDark,
      ),
    );
  }
}
