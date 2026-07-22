import 'package:flutter/material.dart';

import '../onboarding/tutorial_step.dart';
import '../theme/vmfs_colors.dart';

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
              TextButton(onPressed: () => _finish(skipped: true), child: const Text('Skip tour')),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Text(
                      item.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF555555)),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.steps.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? VmfsColors.primaryDark : VmfsColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isFirst ? null : _previous,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
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
