import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const supportYellow = Color(0xFFFFD400);

DateTime _supportDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String _supportTime(dynamic value) {
  final date = _supportDate(value);
  if (date.millisecondsSinceEpoch == 0) return '';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month} $hour:$minute';
}

String _userLabel(User user) {
  final suffix = user.uid.length <= 6
      ? user.uid.toUpperCase()
      : user.uid.substring(user.uid.length - 6).toUpperCase();
  return 'مستخدم #$suffix';
}

class _SupportSession {
  const _SupportSession({required this.threadId});

  final String threadId;
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late final Future<_SupportSession> session = _prepareThread();

  Future<_SupportSession> _prepareThread() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      user = credential.user;
    }
    if (user == null) throw StateError('support-auth-failed');

    final thread = FirebaseFirestore.instance
        .collection('support_threads')
        .doc(user.uid);
    final existing = await thread.get();
    if (!existing.exists) {
      await thread.set({
        'userUid': user.uid,
        'userLabel': _userLabel(user),
        'status': 'open',
        'lastMessage': '',
        'lastSender': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return _SupportSession(threadId: user.uid);
  }

  String _errorMessage(Object? error) {
    if (error is FirebaseAuthException &&
        error.code == 'operation-not-allowed') {
      return 'المراسلة داخل التطبيق قيد الإعداد. حاول مرة ثانية بعد قليل.';
    }
    return 'تعذر فتح مراسلة الدعم. تأكد من الإنترنت وحاول مرة ثانية.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل مع الدعم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<_SupportSession>(
          future: session,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 58),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage(snap.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return _SupportConversation(
              threadId: snap.data!.threadId,
              isAdmin: false,
            );
          },
        ),
      ),
    );
  }
}

class _SupportConversation extends StatefulWidget {
  const _SupportConversation({
    required this.threadId,
    required this.isAdmin,
  });

  final String threadId;
  final bool isAdmin;

  @override
  State<_SupportConversation> createState() => _SupportConversationState();
}

class _SupportConversationState extends State<_SupportConversation> {
  final message = TextEditingController();
  bool sending = false;

  Future<void> _send() async {
    final text = message.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      final thread = FirebaseFirestore.instance
          .collection('support_threads')
          .doc(widget.threadId);
      final messageRef = thread.collection('messages').doc();
      final sender = widget.isAdmin ? 'admin' : 'user';
      final batch = FirebaseFirestore.instance.batch();
      batch.set(messageRef, {
        'sender': sender,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        thread,
        {
          'lastMessage': text,
          'lastSender': sender,
          'status': widget.isAdmin ? 'answered' : 'waiting',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      message.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إرسال الرسالة. تأكد من الإنترنت وحاول مجدداً.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sender = widget.isAdmin ? 'admin' : 'user';
    final messages = FirebaseFirestore.instance
        .collection('support_threads')
        .doc(widget.threadId)
        .collection('messages')
        .orderBy('createdAt', descending: true);
    return Column(
      children: [
        if (!widget.isAdmin)
          const Material(
            color: Color(0xFFFFF4B8),
            child: ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('مراسلة خاصة داخل التطبيق'),
              subtitle: Text('ما يظهر أي رقم هاتف أثناء التواصل.'),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: messages.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('تعذر تحميل الرسائل'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'اكتب رسالتك، والدعم يجاوبك هنا داخل التطبيق.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final mine = data['sender'] == sender;
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 310),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? supportYellow : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['text'] ?? ''}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _supportTime(data['createdAt']),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: message,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sending ? null : _send,
                icon: sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                tooltip: 'إرسال',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminSupportInboxPage extends StatelessWidget {
  const AdminSupportInboxPage({super.key});

  String _statusLabel(Map<String, dynamic> data) {
    switch (data['status']) {
      case 'waiting':
        return 'بانتظار رد الإدارة';
      case 'answered':
        return 'تم الرد';
      case 'closed':
        return 'مغلقة';
      default:
        return 'جديدة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسائل الدعم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('support_threads')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('تعذر تحميل رسائل الدعم'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final threads = snap.data!.docs.toList()
              ..sort(
                (a, b) => _supportDate(b.data()['updatedAt'])
                    .compareTo(_supportDate(a.data()['updatedAt'])),
              );
            if (threads.isEmpty) {
              return const Center(child: Text('ماكو رسائل دعم حالياً'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                final data = thread.data();
                final waiting = data['status'] != 'closed' &&
                    (data['status'] == 'waiting' ||
                        data['lastSender'] == 'user');
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          waiting ? supportYellow : Colors.grey.shade200,
                      child: Icon(
                        waiting ? Icons.mark_chat_unread : Icons.chat,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      '${data['userLabel'] ?? 'مستخدم التطبيق'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${data['lastMessage'] ?? ''}\n${_statusLabel(data)}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminSupportChatPage(
                          threadId: thread.id,
                          userLabel:
                              '${data['userLabel'] ?? 'مستخدم التطبيق'}',
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminSupportChatPage extends StatelessWidget {
  const AdminSupportChatPage({
    super.key,
    required this.threadId,
    required this.userLabel,
  });

  final String threadId;
  final String userLabel;

  Future<void> _close(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('support_threads')
        .doc(threadId)
        .set({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إغلاق المحادثة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userLabel),
        actions: [
          IconButton(
            onPressed: () => _close(context),
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'إغلاق المحادثة',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _SupportConversation(threadId: threadId, isAdmin: true),
      ),
    );
  }
}
