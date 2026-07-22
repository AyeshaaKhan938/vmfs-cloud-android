import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/vmfs_crud_screen.dart';
import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';

final advertisementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisements();
});

final advertisementGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisementGroups();
});

final advertisementTagsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisementTags();
});

class AdvertisementsScreen extends ConsumerWidget {
  const AdvertisementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('advertising') ?? false));
    final repo = ref.read(repositoryProvider);
    final currency = NumberFormat.simpleCurrency();

    return VmfsCrudScreen(
      title: 'Advertisements',
      provider: advertisementsProvider,
      emptyTitle: 'No advertisements',
      canManage: canManage,
      fields: const [
        VmfsCrudField(key: 'title', label: 'Title', required: true),
        VmfsCrudField(key: 'type', label: 'Type (image/video)', initialValue: 'image'),
        VmfsCrudField(key: 'media_path', label: 'Media path / URL'),
        VmfsCrudField(key: 'advertiser_name', label: 'Advertiser'),
        VmfsCrudField(key: 'link_url', label: 'Link URL'),
        VmfsCrudField(key: 'cost', label: 'Cost', keyboardType: TextInputType.number),
        VmfsCrudField(key: 'remarks', label: 'Remarks'),
        VmfsCrudField(key: 'tag_ids', label: 'Tag IDs (comma-separated)'),
      ],
      itemTitle: (item) => item['title'] as String? ?? 'Ad',
      itemSubtitle: (item) {
        final tags = (item['tags'] as List<dynamic>? ?? []).join(', ');
        return '${item['type_label'] ?? item['type']} · ${item['advertiser_name'] ?? ''}${tags.isNotEmpty ? ' · $tags' : ''}';
      },
      itemTrailing: (item) => currency.format((item['cost'] as num?)?.toDouble() ?? 0),
      onCreate: (values) => repo.createAdvertisement(_normalizeAdValues(values)),
      onUpdate: (id, values) => repo.updateAdvertisement(id, _normalizeAdValues(values)),
      onDelete: repo.deleteAdvertisement,
    );
  }
}

Map<String, dynamic> _normalizeAdValues(Map<String, dynamic> values) {
  final tagRaw = values['tag_ids']?.toString().trim() ?? '';
  final tagIds = tagRaw.isEmpty
      ? null
      : tagRaw.split(',').map((part) => int.tryParse(part.trim())).whereType<int>().toList();

  return {
    ...values,
    if (tagIds != null) 'tag_ids': tagIds,
  };
}

class AdvertisementGroupsScreen extends ConsumerWidget {
  const AdvertisementGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('advertising') ?? false));
    final groups = ref.watch(advertisementGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement groups'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Add group',
              onPressed: () async {
                final name = await _promptName(context, title: 'New advertisement group');
                if (name == null || !context.mounted) return;
                try {
                  await ref.read(repositoryProvider).createAdvertisementGroup({'name': name});
                  ref.invalidate(advertisementGroupsProvider);
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: groups.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(advertisementGroupsProvider),
        ),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(advertisementGroupsProvider),
          emptyTitle: 'No advertisement groups',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name'] as String? ?? 'Group'),
              subtitle: Text('${item['advertisement_count'] ?? 0} ads · Screensaver / Top / External'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdvertisementGroupEditorScreen(
                    groupId: item['id'] as int,
                    initialName: item['name'] as String? ?? '',
                    canManage: canManage,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdvertisementGroupEditorScreen extends ConsumerStatefulWidget {
  const AdvertisementGroupEditorScreen({
    super.key,
    required this.groupId,
    required this.initialName,
    required this.canManage,
  });

  final int groupId;
  final String initialName;
  final bool canManage;

  @override
  ConsumerState<AdvertisementGroupEditorScreen> createState() => _AdvertisementGroupEditorScreenState();
}

class _AdvertisementGroupEditorScreenState extends ConsumerState<AdvertisementGroupEditorScreen> {
  late final TextEditingController _nameController;
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _allAds = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      final group = await repo.fetchAdvertisementGroup(widget.groupId);
      final ads = await repo.fetchAdvertisements();
      setState(() {
        _group = group;
        _allAds = ads;
        _nameController.text = _group?['name']?.toString() ?? widget.initialName;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> _slotIds(String slotKey) {
    final slots = _group?['slots'] as Map<String, dynamic>? ?? {};
    final ads = slots[slotKey] as List<dynamic>? ?? [];
    return ads.map((ad) => (ad as Map)['id'] as int).toList();
  }

  Future<void> _editSlot(String slotKey, String label) async {
    if (!widget.canManage) return;

    final selected = Set<int>.from(_slotIds(slotKey));
    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final ad in _allAds)
                            CheckboxListTile(
                              title: Text(ad['title']?.toString() ?? 'Ad'),
                              subtitle: Text('${ad['type_label'] ?? ad['type']} · ${ad['media_path'] ?? 'no media'}'),
                              value: selected.contains(ad['id'] as int),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    selected.add(ad['id'] as int);
                                  } else {
                                    selected.remove(ad['id'] as int);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null) return;

    final slots = Map<String, dynamic>.from(_group?['slots'] as Map<String, dynamic>? ?? {});
    slots[slotKey] = picked.toList();
    setState(() => _group = {...?_group, 'slots': slots});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final slots = _group?['slots'] as Map<String, dynamic>? ?? {};
      await ref.read(repositoryProvider).updateAdvertisementGroup(widget.groupId, {
        'name': _nameController.text.trim(),
        'slots': {
          'screensaver': _slotIdsFromSlots(slots, 'screensaver'),
          'top': _slotIdsFromSlots(slots, 'top'),
          'external_screen': _slotIdsFromSlots(slots, 'external_screen'),
        },
      });
      ref.invalidate(advertisementGroupsProvider);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Advertisement group saved')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<int> _slotIdsFromSlots(Map<String, dynamic> slots, String key) {
    final ads = slots[key] as List<dynamic>? ?? [];
    return ads.map((ad) {
      if (ad is int) return ad;
      return (ad as Map)['id'] as int;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advertisement group')),
        body: const VmfsLoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement group'),
        actions: [
          if (widget.canManage)
            IconButton(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            enabled: widget.canManage,
            decoration: const InputDecoration(labelText: 'Group name'),
          ),
          const SizedBox(height: 16),
          _SlotCard(
            title: 'Screensaver slot',
            ads: (_group?['slots']?['screensaver'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
            onEdit: widget.canManage ? () => _editSlot('screensaver', 'Screensaver slot') : null,
          ),
          _SlotCard(
            title: 'Top slot',
            ads: (_group?['slots']?['top'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
            onEdit: widget.canManage ? () => _editSlot('top', 'Top slot') : null,
          ),
          _SlotCard(
            title: 'External screen',
            ads: (_group?['slots']?['external_screen'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
            onEdit: widget.canManage ? () => _editSlot('external_screen', 'External screen') : null,
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.title, required this.ads, this.onEdit});

  final String title;
  final List<Map<String, dynamic>> ads;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text('Edit ads')),
              ],
            ),
            const SizedBox(height: 8),
            if (ads.isEmpty)
              const Text('No ads assigned')
            else
              ...ads.map(
                (ad) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(ad['title']?.toString() ?? 'Ad'),
                  subtitle: Text('${ad['type_label'] ?? ad['type']} · ${ad['media_path'] ?? ''}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdvertisementTagsScreen extends ConsumerWidget {
  const AdvertisementTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('advertising') ?? false));
    final repo = ref.read(repositoryProvider);
    final tags = ref.watch(advertisementTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement tags'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Add tag',
              onPressed: () async {
                final name = await _promptName(context, title: 'New tag');
                if (name == null || !context.mounted) return;
                try {
                  await repo.createAdvertisementTag({'name': name, 'advertisement_ids': <int>[]});
                  ref.invalidate(advertisementTagsProvider);
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: tags.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(advertisementTagsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(advertisementTagsProvider),
          emptyTitle: 'No tags',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name'] as String? ?? 'Tag'),
              subtitle: Text('${item['advertisement_count'] ?? 0} linked ads'),
              onTap: canManage
                  ? () async {
                      final ads = await repo.fetchAdvertisements();
                      final selected = Set<int>.from((item['advertisement_ids'] as List<dynamic>? ?? []).cast<int>());
                      final picked = await _pickAdvertisements(context, ads, selected, title: item['name']?.toString() ?? 'Tag');
                      if (picked == null || !context.mounted) return;
                      await repo.updateAdvertisementTag(item['id'] as int, {
                        'advertisement_ids': picked.toList(),
                      });
                      ref.invalidate(advertisementTagsProvider);
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _promptName(BuildContext context, {required String title}) async {
  final controller = TextEditingController();
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Name'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
      ],
    ),
  );
  controller.dispose();
  if (value == null || value.isEmpty) return null;
  return value;
}

Future<Set<int>?> _pickAdvertisements(
  BuildContext context,
  List<Map<String, dynamic>> ads,
  Set<int> selected, {
  required String title,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final ad in ads)
                          CheckboxListTile(
                            title: Text(ad['title']?.toString() ?? 'Ad'),
                            subtitle: Text(ad['type_label']?.toString() ?? ad['type']?.toString() ?? ''),
                            value: selected.contains(ad['id'] as int),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selected.add(ad['id'] as int);
                                } else {
                                  selected.remove(ad['id'] as int);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Save')),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
