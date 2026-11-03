import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:major_project/models/notification_model.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/complaint_detail_screen.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'ASSIGNMENT':
        return Icons.person_add_alt_1_rounded;
      case 'STATUS_CHANGE':
        return Icons.published_with_changes_rounded;
      case 'REMARK':
        return Icons.comment_rounded;
      case 'FEEDBACK':
        return Icons.star_rate_rounded;
      case 'SLA_BREACH':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'ASSIGNMENT':
        return Colors.blue;
      case 'STATUS_CHANGE':
        return Colors.green;
      case 'REMARK':
        return Colors.indigo;
      case 'FEEDBACK':
        return Colors.amber.shade800;
      case 'SLA_BREACH':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notifications = provider.notifications;
        final unreadCount = provider.unreadCount;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (notifications.isNotEmpty && unreadCount > 0)
                TextButton(
                  key: const Key('mark_all_read_button'),
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(silent: false),
            child: provider.isLoading && notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null && notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                provider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.fetchNotifications(),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'Your inbox is empty',
                                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Updates regarding your lodged complaints will appear here.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return _buildNotificationTile(item, provider);
                            },
                          ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel item, NotificationProvider provider) {
    final typeColor = _colorForType(item.type);
    final timeStr = item.createdAt != null
        ? DateFormat('MMM dd, hh:mm a').format(item.createdAt!)
        : '';

    return Material(
      color: item.read ? Colors.transparent : Colors.indigo.shade50.withValues(alpha: 0.4),
      child: ListTile(
        key: Key('notification_tile_${item.id}'),
        onTap: () {
          if (!item.read) {
            provider.markAsRead(item.id);
          }
          final compLookup = item.relatedComplaintMongoId ?? item.complaintId;
          if (compLookup.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComplaintDetailScreen(complaintId: compLookup),
              ),
            );
          }
        },
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: typeColor.withValues(alpha: 0.12),
              child: Icon(_iconForType(item.type), color: typeColor, size: 22),
            ),
            if (!item.read)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  key: Key('unread_dot_${item.id}'),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.message,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              if (item.complaintId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Ticket #${item.complaintId}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
