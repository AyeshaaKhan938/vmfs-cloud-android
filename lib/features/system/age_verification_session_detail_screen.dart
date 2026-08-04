import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import 'age_verification_utils.dart';
import 'system_screens.dart';

class AgeVerificationSessionDetailScreen extends ConsumerStatefulWidget {
  const AgeVerificationSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AgeVerificationSessionDetailScreen> createState() => _AgeVerificationSessionDetailScreenState();
}

class _AgeVerificationSessionDetailScreenState extends ConsumerState<AgeVerificationSessionDetailScreen> {
  Map<String, dynamic>? _session;
  Uint8List? _documentBytes;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(repositoryProvider);
      final session = await repo.fetchAgeVerificationSession(widget.sessionId);
      Uint8List? documentBytes;

      if (session['has_document'] == true) {
        final bytes = await repo.fetchAgeVerificationDocument(widget.sessionId);
        documentBytes = Uint8List.fromList(bytes);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
        _documentBytes = documentBytes;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _copyVerifyUrl() async {
    final url = _session?['verify_url'] as String?;
    if (url == null || url.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification link copied')),
      );
    }
  }

  Future<void> _approve() async {
    await _review(approved: true);
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        final isRevoke = _session?['status'] == 'verified';
        return AlertDialog(
          title: Text(isRevoke ? 'Revoke verification?' : 'Reject verification?'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              hintText: isRevoke ? 'Document did not match customer' : 'ID image was unreadable',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(isRevoke ? 'Revoke' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) {
      return;
    }

    await _review(approved: false, message: reason.isEmpty ? null : reason);
  }

  Future<void> _review({required bool approved, String? message}) async {
    final wasVerified = !approved && _session?['status'] == 'verified';

    setState(() => _acting = true);
    try {
      final repo = ref.read(repositoryProvider);
      final updated = approved
          ? await repo.approveAgeVerificationSession(widget.sessionId, message: message)
          : await repo.rejectAgeVerificationSession(widget.sessionId, message: message);

      ref.invalidate(ageVerificationSessionsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _session = updated;
        _acting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Verification approved' : (wasVerified ? 'Verification revoked' : 'Verification rejected'))),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification session')),
      body: _loading
          ? const VmfsLoadingView()
          : _error != null
              ? VmfsErrorView(message: _error!, onRetry: _load)
              : session == null
                  ? const VmfsEmptyState(title: 'Session not found', message: 'This verification session is no longer available.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Machine ${session['machine_no'] ?? '—'}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                              ),
                              VmfsStatusPill(
                                label: ageVerificationStatusLabel(session),
                                color: ageVerificationStatusColor(session['status'] as String?),
                              ),
                            ],
                          ),
                          if ((session['message'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Text(session['message'] as String, style: const TextStyle(color: VmfsColors.textSecondary)),
                          ],
                          const SizedBox(height: 16),
                          _InfoRow(label: 'Session ID', value: session['session_id']?.toString() ?? '—'),
                          _InfoRow(label: 'Created', value: formatAgeVerificationTimestamp(session['created_at'] as String?)),
                          _InfoRow(label: 'Expires', value: formatAgeVerificationTimestamp(session['expires_at'] as String?)),
                          _InfoRow(label: 'Verified', value: formatAgeVerificationTimestamp(session['verified_at'] as String?)),
                          if (session['document_type'] != null)
                            _InfoRow(label: 'Document type', value: session['document_type'].toString()),
                          const SizedBox(height: 16),
                          if (_documentBytes != null) ...[
                            const Text('Submitted ID document', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_documentBytes!, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if ((session['verify_url'] as String?)?.isNotEmpty == true)
                            OutlinedButton.icon(
                              onPressed: _copyVerifyUrl,
                              icon: const Icon(Icons.link),
                              label: const Text('Copy customer verification link'),
                            ),
                          if (session['can_approve'] == true) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Review this submission and approve access for the kiosk purchase.',
                              style: TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _acting ? null : _approve,
                              icon: const Icon(Icons.verified_user_outlined),
                              label: const Text('Approve verification'),
                            ),
                          ],
                          if (session['can_reject'] == true) ...[
                            const SizedBox(height: 16),
                            if (session['can_approve'] != true)
                              const Text(
                                'This customer was verified automatically or manually. Revoke if the ID documents were invalid.',
                                style: TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                              ),
                            if (session['can_approve'] != true) const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _acting ? null : _reject,
                              icon: const Icon(Icons.block),
                              label: Text(
                                session['status'] == 'verified'
                                    ? 'Revoke verification'
                                    : 'Reject verification',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: VmfsColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
