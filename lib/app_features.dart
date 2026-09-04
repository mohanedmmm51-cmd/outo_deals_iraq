import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const appFeaturesYellow = Color(0xFFFFD400);

class AppFeatureItem {
  const AppFeatureItem({
    required this.id,
    required this.title,
    required this.description,
    this.active = true,
  });

  final String id;
  final String title;
  final String description;
  final bool active;

  AppFeatureItem copyWith({
    String? title,
    String? description,
    bool? active,
  }) {
    return AppFeatureItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }

  factory AppFeatureItem.fromMap(Map<String, dynamic> data, int index) {
    return AppFeatureItem(
      id: '${data['id'] ?? 'feature_$index'}',
      title: '${data['title'] ?? ''}'.trim(),
      description: '${data['description'] ?? ''}'.trim(),
      active: data['active'] != false,
    );
  }

  Map<String, dynamic> toMap(int order) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'active': active,
      'order': order,
    };
  }
}

const defaultAppFeatures = <AppFeatureItem>[
  AppFeatureItem(
    id: 'tire_replacement',
    title: 'خدمة تبديل الإطارات',
    description:
        'إذا اشتريت الإطار من عدنا، التوصيل علينا والتركيب بالمحل علينا.',
  ),
];

List<AppFeatureItem> _readFeatures(
  DocumentSnapshot<Map<String, dynamic>>? document,
) {
  if (document == null || !document.exists) {
    return List<AppFeatureItem>.of(defaultAppFeatures);
  }

  final raw = document.data()?['features'];
  if (raw is! List) return <AppFeatureItem>[];

  final entries = <({int order, AppFeatureItem feature})>[];
  for (var index = 0; index < raw.length; index++) {
    final value = raw[index];
    if (value is! Map) continue;
    final data = Map<String, dynamic>.from(value);
    final feature = AppFeatureItem.fromMap(data, index);
    if (feature.title.isEmpty || feature.description.isEmpty) continue;
    entries.add((
      order: (data['order'] as num?)?.toInt() ?? index,
      feature: feature,
    ));
  }
  entries.sort((a, b) => a.order.compareTo(b.order));
  return entries.map((entry) => entry.feature).toList();
}

class AppFeaturesSection extends StatelessWidget {
  const AppFeaturesSection({
    super.key,
    required this.onNearbyShopsTap,
  });

  final VoidCallback onNearbyShopsTap;

  @override
  Widget build(BuildContext context) {
    final reference = FirebaseFirestore.instance
        .collection('app_content')
        .doc('home_features');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: reference.snapshots(),
      builder: (context, snapshot) {
        final features = _readFeatures(snapshot.data)
            .where((feature) => feature.active)
            .toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'مميزات التطبيق',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (features.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: appFeaturesYellow.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tire_repair, size: 31),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(feature.description),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff111111),
                  foregroundColor: appFeaturesYellow,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: onNearbyShopsTap,
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'شوف المحلات القريبة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminAppFeaturesPage extends StatelessWidget {
  const AdminAppFeaturesPage({super.key});

  DocumentReference<Map<String, dynamic>> get _reference =>
      FirebaseFirestore.instance.collection('app_content').doc('home_features');

  Future<void> _save(List<AppFeatureItem> features) {
    return _reference.set({
      'sectionTitle': 'مميزات التطبيق',
      'features': [
        for (var index = 0; index < features.length; index++)
          features[index].toMap(index),
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _edit(
    BuildContext context,
    List<AppFeatureItem> features, {
    AppFeatureItem? current,
  }) async {
    final title = TextEditingController(text: current?.title ?? '');
    final description = TextEditingController(text: current?.description ?? '');
    var active = current?.active ?? true;

    final result = await showDialog<AppFeatureItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'إضافة ميزة' : 'تعديل الميزة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الميزة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'شرح الميزة',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ظاهرة للزبائن'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final cleanTitle = title.text.trim();
                final cleanDescription = description.text.trim();
                if (cleanTitle.isEmpty || cleanDescription.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  AppFeatureItem(
                    id: current?.id ??
                        'feature_${DateTime.now().microsecondsSinceEpoch}',
                    title: cleanTitle,
                    description: cleanDescription,
                    active: active,
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    description.dispose();
    if (result == null) return;

    final updated = List<AppFeatureItem>.of(features);
    final index = updated.indexWhere((feature) => feature.id == result.id);
    if (index == -1) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    await _save(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ مميزات التطبيق')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    List<AppFeatureItem> features,
    AppFeatureItem current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الميزة؟'),
        content: Text('راح تنحذف «${current.title}» من الصفحة الرئيسية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _save(
      features.where((feature) => feature.id != current.id).toList(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الميزة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة مميزات التطبيق')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _reference.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('تعذر تحميل المميزات: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final features = _readFeatures(snapshot.data);
            return Stack(
              children: [
                if (features.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'ماكو ميزات مضافة حالياً. زر المحلات القريبة يبقى ظاهر للزبائن.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            feature.active
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: feature.active ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            feature.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(feature.description),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _edit(context, features, current: feature);
                              } else if (action == 'toggle') {
                                final updated = List<AppFeatureItem>.of(features);
                                updated[index] = feature.copyWith(
                                  active: !feature.active,
                                );
                                _save(updated);
                              } else if (action == 'delete') {
                                _delete(context, features, feature);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('تعديل'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  feature.active ? 'إخفاء' : 'إظهار',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: FloatingActionButton.extended(
                    onPressed: () => _edit(context, features),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة ميزة'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
