import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_theme.dart';
import '../widgets/ticket_detail_sheet.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _markAllAsRead(user.uid),
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isSeen = data['isSeen'] as bool? ?? false;
              final title = data['title'] as String? ?? 'Notification';
              final body = data['body'] as String? ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final ticketId = data['ticketId'] as String?;
              final status = data['status'] as String?;

              final timeString = createdAt != null
                  ? DateFormat('MMM d, h:mm a').format(createdAt.toDate())
                  : 'Just now';

              Color iconBgColor = Colors.grey.shade200;
              Color iconColor = Colors.grey.shade700;
              IconData iconData = Icons.info_outline;

              if (status == 'Approved/Resolved') {
                iconBgColor = isDark
                    ? Colors.green.withOpacity(0.2)
                    : Colors.green.shade100;
                iconColor = isDark ? Colors.greenAccent : Colors.green.shade700;
                iconData = Icons.check_circle_outline;
              } else if (status == 'Rejected' || status == 'Cancelled') {
                iconBgColor = isDark
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.shade100;
                iconColor = isDark ? Colors.redAccent : Colors.red.shade700;
                iconData = Icons.cancel_outlined;
              }

              return Card(
                elevation: isSeen ? 0 : 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: isSeen
                    ? (isDark ? Colors.grey.shade900 : Colors.white)
                    : (isDark
                        ? theme.primaryColor.withOpacity(0.15)
                        : Colors.blue.shade50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSeen
                        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                        : theme.primaryColor.withOpacity(isDark ? 0.3 : 0.5),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!isSeen) {
                      doc.reference.update({'isSeen': true});
                    }
                    if (ticketId != null) {
                      _showTicketDetails(context, ticketId);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: isSeen
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!isSeen)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                body,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeString,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isSeen', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isSeen': true});
    }

    await batch.commit();
  }

  Future<void> _showTicketDetails(BuildContext context, String ticketId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .get();
      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket not found')),
          );
        }
        return;
      }
      if (context.mounted) {
        AppTheme.showAppModalBottomSheet(
          context: context,
          builder: TicketDetailSheet(
            data: doc.data() as Map<String, dynamic>,
            docId: doc.id,
            onEdit: () {}, // Can't edit from view
            onCancel: (id) async {
              await FirebaseFirestore.instance
                  .collection('tickets')
                  .doc(id)
                  .update({'status': 'Cancelled'});
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ticket: $e')),
        );
      }
    }
  }
}
