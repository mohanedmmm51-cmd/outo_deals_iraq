part of '../advanced_features.dart';

class MediaGalleryPage extends StatefulWidget {
  const MediaGalleryPage({super.key});

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  late final Future<ShopProfile?> shopSession;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    shopSession = ShopStore.loadForAuthenticatedOwner();
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _extension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return 'jpg';
  }

  Future<void> _upload() async {
    if (busy) return;
    final shop = await shopSession;
    final user = FirebaseAuth.instance.currentUser;
    if (shop == null || !shop.approved || user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجل دخول محل معتمد حتى ترفع صورة')),
        );
      }
      return;
    }

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    setState(() => busy = true);
    Reference? uploadedReference;
    var uploadCompleted = false;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        throw StateError('حجم الصورة لازم يكون أقل من 8 ميگابايت');
      }
      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}.${_extension(file.name)}';
      final storagePath = 'media/${user.uid}/$fileName';
      uploadedReference = FirebaseStorage.instance.ref(storagePath);
      await uploadedReference.putData(
        bytes,
        SettableMetadata(
          contentType: _contentType(file.name),
          customMetadata: {'ownerUid': user.uid, 'shopId': shop.id},
        ),
      );
      uploadCompleted = true;
      final url = await uploadedReference.getDownloadURL();
      await FirebaseFirestore.instance.collection('media').add({
        'url': url,
        'storagePath': storagePath,
        'type': 'shop',
        'ownerUid': user.uid,
        'shopId': shop.id,
        'shopName': shop.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة باسم المحل')),
        );
      }
    } catch (error) {
      if (uploadCompleted && uploadedReference != null) {
        try {
          await uploadedReference.delete();
        } catch (_) {}
      }
      if (mounted) {
        final message = error is StateError
            ? error.toString().replaceFirst('Bad state: ', '')
            : 'تعذر رفع الصورة. حاول مرة ثانية.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopProfile?>(
      future: shopSession,
      builder: (context, shopSnapshot) {
        final canUpload = shopSnapshot.data?.approved == true;
        return Scaffold(
          appBar: AppBar(title: const Text('الصور')),
          floatingActionButton: canUpload
              ? FloatingActionButton(
                  onPressed: busy ? null : _upload,
                  child: busy
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.add_a_photo),
                )
              : null,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('media')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل الصور'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ماكو صور مرفوعة حالياً'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data();
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            '${data['url'] ?? ''}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                          if ('${data['shopName'] ?? ''}'.trim().isNotEmpty)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black54,
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${data['shopName']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
